// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Escrow.sol";
import "./RewardToken.sol";
import "./Treasury.sol";
import "./Core.sol";
import "forge-std/console.sol";

contract PropertyAuction is Ownable {

    uint256 public startingPrice;
    uint256 public currentWinningBidAmount;
    uint256 public buyersRemorsePeriod;
    uint256 public auctionClosedTime;
    uint256 public listingId;

    address public currentWinningBidder;
    address public treasury;
    address public propertyOwner;
    address public core;
    address public rewardToken;

    bool public auctionStillOpen;
    string public uri;

    mapping(address => uint256) public userCredit;

    
    constructor(
        string memory _uri,
        uint256 _startingPrice, 
        uint256 _buyersRemorsePeriod, 
        uint256 _listingId,
        address _treasury, 
        address _propertyOwner,
        address _rewardToken
    ) Ownable(_propertyOwner) {
        uri = _uri;
        startingPrice = _startingPrice;
        currentWinningBidAmount = _startingPrice;
        buyersRemorsePeriod = _buyersRemorsePeriod;
        listingId = _listingId;
        auctionStillOpen = true;
        treasury = _treasury;
        core = msg.sender;
        propertyOwner = _propertyOwner;
        rewardToken = _rewardToken;
    }

    function bidWithETH() external payable {
        require(msg.value > currentWinningBidAmount, "Bid too low");
        require(auctionStillOpen, "Auction closed");

        userCredit[currentWinningBidder] += currentWinningBidAmount;

        currentWinningBidAmount = msg.value;
        currentWinningBidder = msg.sender;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.MADE_OFFER, 
            msg.value, 
            msg.sender
        );
    }

    function bidWithCredit(uint256 _amount) external {
        require(_amount > currentWinningBidAmount, "Bid too low");
        require(auctionStillOpen, "Auction closed");
        require(userCredit[msg.sender] >= _amount, "Not enough credit");

        userCredit[currentWinningBidder] += currentWinningBidAmount;
        currentWinningBidAmount = _amount;
        currentWinningBidder = msg.sender;
        userCredit[msg.sender] -= _amount;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.MADE_OFFER, 
            _amount, 
            msg.sender
        );
        
    }

    function withdrawFunds(uint256 _amount) external {
        require(userCredit[msg.sender] >= _amount, "Not enough funds");

        userCredit[msg.sender] -= _amount;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function closeAuction() external onlyOwner {
        require(auctionStillOpen, "Auction closed");

        (,,,,, Core.Listing_Status status,,) = Core(payable(core)).listings(listingId);
        require(status == Core.Listing_Status.LISTED, "Auction not currently listed");

        auctionClosedTime = block.timestamp;
        auctionStillOpen = false;

        Core(payable(core)).updateAuctionStatus(listingId, Core.Listing_Status.UNDER_OFFER);
    }

    function bailOutOfPurchase() external {
        require(msg.sender == currentWinningBidder, "Not current winning bidder");
        require(!auctionStillOpen, "Auction still open");
        require(block.timestamp <= auctionClosedTime + buyersRemorsePeriod, "Buyers remorse over");

        (,,,,, Core.Listing_Status status,,) = Core(payable(core)).listings(listingId);
        require(status == Core.Listing_Status.UNDER_OFFER, "Auction not under offer");

        userCredit[msg.sender] += currentWinningBidAmount;
        currentWinningBidder = address(0);
        currentWinningBidAmount = startingPrice;
        auctionStillOpen = true;

        Core(payable(core)).updateAuctionStatus(listingId, Core.Listing_Status.LISTED);

    }

    function cancelAuction() external {
        require(msg.sender == address(payable(core)), "Not called by Core.sol");

        auctionStillOpen = false;
    }

    function settleAuction() external onlyOwner {
        require(block.timestamp >= auctionClosedTime + buyersRemorsePeriod, "Buyers remorse time");
        require(!auctionStillOpen, "Auction closed");

        (,,,,, Core.Listing_Status status,,) = Core(payable(core)).listings(listingId);
        require(status == Core.Listing_Status.UNDER_OFFER, "Auction not under offer");

        uint256 treasuryFee = Treasury(payable(treasury)).protocolFee();
        uint256 treasuryAmount = currentWinningBidAmount * treasuryFee / 10000;
        uint256 sellerAmount = currentWinningBidAmount - treasuryAmount;

        auctionStillOpen = false;
        userCredit[propertyOwner] += sellerAmount;

        Core(payable(core)).updateAuctionWinner(listingId, currentWinningBidder);
        Core(payable(core)).updateAuctionStatus(listingId, Core.Listing_Status.SOLD);

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.PURCHASED_PROPERTY, 
            currentWinningBidAmount, 
            currentWinningBidder
        );

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.SOLD_PROPERTY, 
            currentWinningBidAmount, 
            owner()
        );

        (bool sent, ) = payable(treasury).call{value: treasuryAmount}("");
        require(sent, "Failed to send Ether");

    }
}