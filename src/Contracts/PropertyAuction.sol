// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Escrow.sol";
import "./RewardToken.sol";
import "./Treasury.sol";

contract PropertyAuction is Ownable {

    uint256 public startingPrice;
    uint256 public currentWinningBidAmount;
    uint256 public buyersRemorsePeriod;
    uint256 public auctionClosedTime;

    address public currentWinningBidder;
    address public treasury;
    address public propertyOwner;

    bool public auctionStillOpen;
    string public uri;

    mapping(address => uint256) public userCredit;

    
    constructor(
        string memory _uri,
        uint256 _startingPrice, 
        uint256 _buyersRemorsePeriod, 
        address _treasury, 
        address _propertyOwner
    ) Ownable(_propertyOwner) {
        uri = _uri;
        startingPrice = _startingPrice;
        currentWinningBidAmount = _startingPrice;
        buyersRemorsePeriod = _buyersRemorsePeriod;
        auctionStillOpen = true;
        treasury = _treasury;
        propertyOwner = _propertyOwner;
    }

    function bidWithETH() external payable {
        require(msg.value > currentWinningBidAmount, "Bid too low");
        require(auctionStillOpen, "Auction closed");

        currentWinningBidAmount = msg.value;
        currentWinningBidder = msg.sender;
    }

    function bidWithCredit(uint256 _amount) external {
        require(auctionStillOpen, "Auction closed");
        require(userCredit[msg.sender] >= _amount, "Not enough credit");

        if(_amount > currentWinningBidAmount) {
            currentWinningBidAmount = _amount;
            currentWinningBidder = msg.sender;
            userCredit[msg.sender] -= _amount;
        }
    }

    function withdrawFunds(uint256 _amount) external {
        require(userCredit[msg.sender] >= _amount, "Not enough funds");

        userCredit[msg.sender] -= _amount;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    function closeAuction() external onlyOwner {
        require(auctionStillOpen, "Auction closed");

        auctionClosedTime = block.timestamp;

        auctionStillOpen = false;
    }

    function bailOutOfPurchase() external {
        require(msg.sender == currentWinningBidder, "Not current winning bidder");
        require(!auctionStillOpen, "Auction still open");
        require(block.timestamp <= auctionClosedTime + buyersRemorsePeriod, "Buyers remorse over");

        userCredit[msg.sender] += currentWinningBidAmount;

        auctionStillOpen = true;

    }

    function settleAuction() external onlyOwner {
        require(block.timestamp >= auctionClosedTime + buyersRemorsePeriod, "Buyers remorse time");
        require(!auctionStillOpen, "Auction closed");

        uint256 treasuryFee = Treasury(payable(treasury)).protocolFee();
        uint256 treasuryAmount = currentWinningBidAmount * treasuryFee / 10000;
        uint256 sellerAmount = currentWinningBidAmount - treasuryAmount;

        (bool sent, ) = payable(treasury).call{value: treasuryAmount}("");
        require(sent, "Failed to send Ether");

        userCredit[propertyOwner] += sellerAmount;
    }
}