// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Escrow.sol";
import "./RewardToken.sol";
import "./PropertyAuction.sol";
import "./Treasury.sol";

contract Core is Ownable {

    enum Listing_Status {
        LISTED,
        UNDER_OFFER,
        SOLD,
        CANCELLED
    }

    enum List_Type {
        STANDARD,
        AUCTION,
        GIVEAWAY
    }

    struct Listing {
        uint256 listingId;
        uint256 price;
        uint256 numberOfOffers;
        address finalizedBuyer;
        address owner;
        Listing_Status status;
        List_Type typeOfListing;
        string ipfsHash;
    }

    // timeOfOffer refers to when the offer was created
    // offerLength refers to how long the offer is valid for
    struct Offer {
        uint256 offerId;
        uint256 listingId;
        uint256 offerAmount;
        uint256 timeOfOffer;
        uint256 offerLength;
        address offerOwner;
        address escrowContract;
        bool accepted;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => mapping(uint256 => Offer)) public offersPerListing;
    mapping(uint256 => address) public auctions;
    mapping(uint256 => mapping(uint256 => address)) public giveawayValidAddresses;
    mapping(uint256 => mapping(address => bool)) public giveawayOptedIn;
    mapping(uint256 => uint256) public giveawayAmountRaised;
    mapping(address => uint256) public userCredit;

    uint256 public numberOfListings = 1;

    address public treasury;
    address public rewardToken;

    // --------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------ CONSTRUCTOR -------------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

    constructor(address _treasury, address _rewardToken) Ownable(msg.sender) {
        treasury = _treasury;
        rewardToken = _rewardToken;
    }

    // --------------------------------------------------------------------------------------------------------------------
    // --------------------------------------- STANDARD LISTING FUNCTIONALITY ---------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

    // Anyone can create a standard listing
    // The URI for all listings is a link to an IPFS hash with all the property information
    function listSale(string memory _uri, uint256 _price) external {
        listings[numberOfListings] = Listing({
            listingId: numberOfListings,
            price: _price,
            numberOfOffers: 0,
            finalizedBuyer: address(0),
            owner: msg.sender,
            status: Listing_Status.LISTED,
            typeOfListing: List_Type.STANDARD,
            ipfsHash: _uri
        });

        numberOfListings++;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.LISTED_PROPERTY, 
            _price, 
            msg.sender
        );
    }

    // Anyone can make an offer on a standard listing
    function makeOffer(uint256 _listingId, uint256 _offerLength) external payable {        
        require(listings[_listingId].listingId != 0, "Listing does not exist");
        require(
            listings[_listingId].status == Listing_Status.LISTED || 
            listings[_listingId].status == Listing_Status.UNDER_OFFER, 
            "Listing cancelled or sold"
        );
        
        listings[_listingId].numberOfOffers++;

        uint256 numberOfOffersForListing = listings[_listingId].numberOfOffers;
        offersPerListing[_listingId][numberOfOffersForListing] = Offer({
            offerId: numberOfOffersForListing,
            listingId: _listingId,
            offerAmount: msg.value,
            timeOfOffer: block.timestamp,
            offerLength: _offerLength,
            offerOwner: msg.sender,
            escrowContract: address(0),
            accepted: false
        });

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.MADE_OFFER, 
            msg.value, 
            msg.sender
        );
    }

    // A user can cancel their offer
    function cancelOffer(uint256 _listingId, uint256 _offerId) external {
        require(msg.sender == offersPerListing[_listingId][_offerId].offerOwner, "Not offer owner");
        require(offersPerListing[_listingId][_offerId].escrowContract == address(0), "Offer has already been accepted");

        offersPerListing[_listingId][_offerId].offerLength = 0;
        userCredit[msg.sender] += offersPerListing[_listingId][_offerId].offerAmount;
    }

    // The creator of a listing can accept an offer
    function acceptOffer(uint256 _listingId, uint256 _offerId) external returns (address) {
        Offer storage offer = offersPerListing[_listingId][_offerId];
        require(!offer.accepted, "Offer already accepted");
        require(msg.sender == listings[_listingId].owner, "Not listing owner");
        require(
            listings[_listingId].status == Listing_Status.LISTED || 
            listings[_listingId].status == Listing_Status.UNDER_OFFER, 
            "Listing cancelled or sold"
        );
        require(offer.listingId == _listingId, "Offer not apart of supplied listing");
        require(block.timestamp <= offer.timeOfOffer + offer.offerLength, "Offer has run out");

        Escrow escrowContract = new Escrow(
            _listingId, 
            _offerId, 
            owner(), 
            listings[_listingId].owner, 
            offersPerListing[_listingId][_offerId].offerOwner, 
            address(this),
            treasury
        );
        
        listings[_listingId].status = Listing_Status.UNDER_OFFER;
        offer.escrowContract = address(escrowContract);
        offersPerListing[_listingId][_offerId].accepted = true;

        (bool sent, ) = address(escrowContract).call{value: offer.offerAmount}("");
        require(sent, "Failed to send Ether");

        return address(escrowContract);
    }

    // The escrow contract can call this function to tell the Core contract that a listing has successfully completed
    function markOfferComplete(uint256 _listingId, uint256 _offerId) external {
        require(msg.sender == offersPerListing[_listingId][_offerId].escrowContract, "Incorrect caller");

        listings[_listingId].status = Listing_Status.SOLD;
        listings[_listingId].finalizedBuyer = offersPerListing[_listingId][_offerId].offerOwner;
        offersPerListing[_listingId][_offerId].offerLength = 0;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.SOLD_PROPERTY, 
            offersPerListing[_listingId][_offerId].offerAmount, 
            listings[_listingId].owner
        );

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.PURCHASED_PROPERTY, 
            offersPerListing[_listingId][_offerId].offerAmount, 
            offersPerListing[_listingId][_offerId].offerOwner
        );
    }

    // The escrow contract can call this function to tell the Core contract that a listing has been rejected and must be re-opened
    function markOfferFailed(uint256 _listingId, uint256 _offerId) external {
        require(msg.sender == offersPerListing[_listingId][_offerId].escrowContract, "Incorrect caller");

        listings[_listingId].status = Listing_Status.LISTED;
        offersPerListing[_listingId][_offerId].accepted = false;
    }

    // --------------------------------------------------------------------------------------------------------------------
    // -------------------------------------------- AUCTION FUNCTIONALITY -------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------
    
    // Anyone can list a property for sale via an auction
    function listSaleForAuction(
        string memory _uri, 
        uint256 _startingPrice,
        uint256 _buyersRemorsePeriod
    ) external returns (address) {
        PropertyAuction propertyAuction = new PropertyAuction(
            _uri, 
            _startingPrice, 
            _buyersRemorsePeriod, 
            numberOfListings,
            treasury, 
            msg.sender,
            rewardToken
        );

        //Number of offers stays 0 for auction listings
        listings[numberOfListings] = Listing({
            listingId: numberOfListings,
            price: _startingPrice,
            numberOfOffers: 0,
            finalizedBuyer: address(0),
            owner: msg.sender,
            status: Listing_Status.LISTED,
            typeOfListing: List_Type.AUCTION,
            ipfsHash: _uri
        });

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.LISTED_PROPERTY, 
            _startingPrice, 
            msg.sender
        );

        auctions[numberOfListings] = address(propertyAuction);
        numberOfListings++;

        return address(propertyAuction);
    }

    // An auction contract can tell the Core contract that an auction has a winner
    function updateAuctionWinner(uint256 _listingId, address _winner) external {
        require(msg.sender == auctions[_listingId], "Incorrect auction contract");

        listings[_listingId].finalizedBuyer = _winner;
    }

    // An auction contract can tell the Core contract that an auction has changed status
    function updateAuctionStatus(uint256 _listingId, Listing_Status _status) external {
        require(msg.sender == auctions[_listingId], "Incorrect auction contract");

        listings[_listingId].status = _status;
    }

    // --------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------- GIVEAWAY FUNCTIONALITY -------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

    // Anyone can list a property via a giveaway
    function createGiveaway(
        string memory _uri,
        uint256 _eligibilityAmount
    ) external {

        listings[numberOfListings] = Listing({
            listingId: numberOfListings,
            price: _eligibilityAmount,
            numberOfOffers: 0,
            finalizedBuyer: address(0),
            owner: msg.sender,
            status: Listing_Status.LISTED,
            typeOfListing: List_Type.GIVEAWAY,
            ipfsHash: _uri
        });

        numberOfListings++;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.LISTED_PROPERTY, 
            _eligibilityAmount, 
            msg.sender
        );
    }

    // Anyone can opt into giveaways buy paying the giveaway entrance
    function optIntoGiveaway(uint256 _giveawayId) external payable {
        require(msg.value == listings[_giveawayId].price, "Incorrect value");
        require(!giveawayOptedIn[_giveawayId][msg.sender], "Already opted in");
        require(listings[_giveawayId].typeOfListing == List_Type.GIVEAWAY, "Not a giveaway");
        require(listings[_giveawayId].status == Listing_Status.LISTED, "Listing already sold");

        giveawayValidAddresses[_giveawayId][listings[_giveawayId].numberOfOffers] = msg.sender;
        giveawayOptedIn[_giveawayId][msg.sender] = true;
        listings[_giveawayId].numberOfOffers++;

        giveawayAmountRaised[_giveawayId] += msg.value;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.MADE_OFFER, 
            msg.value, 
            msg.sender
        );
    }

    // The giveaway creator can close the giveaway and a winner will be selected
    function closeGiveaway(uint256 _giveawayId) external returns (address) {
        require(msg.sender == listings[_giveawayId].owner || msg.sender == owner(), "Invalid permissions");
        require(listings[_giveawayId].status == Listing_Status.LISTED, "Listing already sold");
        uint256 numberOfParticipants = listings[_giveawayId].numberOfOffers;

        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    msg.sender, 
                    numberOfParticipants, 
                    block.timestamp,
                    "GIVEAWAY",
                    _giveawayId
                )
            )
        ) % listings[_giveawayId].numberOfOffers;

        address winner = giveawayValidAddresses[_giveawayId][randomNumber];

        listings[_giveawayId].finalizedBuyer = winner;
        listings[_giveawayId].status = Listing_Status.SOLD;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.PURCHASED_PROPERTY, 
            listings[_giveawayId].price, 
            winner
        );

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.SOLD_PROPERTY, 
            listings[_giveawayId].price, 
            listings[_giveawayId].owner
        );

        uint256 treasuryFee = Treasury(payable(treasury)).protocolFee();
        uint256 treasuryAmount = giveawayAmountRaised[_giveawayId] * treasuryFee / 10000;
        uint256 sellerAmount = giveawayAmountRaised[_giveawayId] - treasuryAmount;

        userCredit[listings[_giveawayId].owner] += sellerAmount;

        (bool sent, ) = address(treasury).call{value: treasuryAmount}("");
        require(sent, "Failed to send Ether");

        return winner;
    }

    // --------------------------------------------------------------------------------------------------------------------
    // ---------------------------------------------- GENERAL FUNCTIONALITY -----------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

    // Users who have credit can use this function to withdraw ETH
    function withdrawFunds(uint256 _amount) external {
        require(userCredit[msg.sender] >= _amount, "Insufficient balance");

        userCredit[msg.sender] -= _amount;

        (bool sent, ) = msg.sender.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }

    // Owners of listings can cancel their listings
    function cancelListing(uint256 _listingId) external {
        require(msg.sender == listings[_listingId].owner, "Not listing creator");
        

        if(listings[_listingId].typeOfListing == List_Type.AUCTION) {
            PropertyAuction(auctions[_listingId]).cancelAuction();
        } else if(listings[_listingId].typeOfListing == List_Type.GIVEAWAY){
            require(listings[_listingId].numberOfOffers == 0, "Already received offers");
        } else {
            require(listings[_listingId].status == Listing_Status.LISTED, "Listing already cancelled or sold");
        }

        listings[_listingId].status = Listing_Status.CANCELLED;
    }

    //Allows ether to be sent to this contract
    receive() external payable {}
}