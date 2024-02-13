// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "./Escrow.sol";
import "./RewardToken.sol";
import "./PropertyAuction.sol";

contract Core is Ownable {

    enum Listing_Status {
        LISTED,
        UNDER_OFFER,
        SOLD,
        CANCELLED
    }

    struct Listing {
        uint256 listingId;
        uint256 price;
        uint256 numberOfOffers;
        uint256 winningOffer;
        address owner;
        Listing_Status status;
        string ipfsHash;
    }

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

    uint256 public numberOfListings = 1;

    address public treasury;
    address public rewardToken;

    constructor(address _treasury, address _rewardToken) Ownable(msg.sender) {
        treasury = _treasury;
        rewardToken = _rewardToken;
    }

    function listSale(string memory _uri, uint256 _price) external {
        listings[numberOfListings] = Listing({
            listingId: numberOfListings,
            price: _price,
            numberOfOffers: 0,
            winningOffer: 0,
            owner: msg.sender,
            status: Listing_Status.LISTED,
            ipfsHash: _uri
        });

        numberOfListings++;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.LISTED_PROPERTY, 
            _price, 
            msg.sender
        );
    }

    function listSaleForAuction(
        string memory _uri, 
        uint256 _startingPrice,
        uint256 _buyersRemorsePeriod
    ) external returns (address) {
        PropertyAuction propertyAuction = new PropertyAuction(_uri, _startingPrice, _buyersRemorsePeriod, treasury, msg.sender);

        auctions[numberOfListings] = address(propertyAuction);
        numberOfListings++;

        return address(propertyAuction);
    }

    function cancelListing(uint256 _listingId) external {
        require(msg.sender == listings[_listingId].owner, "Not listing creator");
        require(
            listings[_listingId].status == Listing_Status.LISTED, "Listing already cancelled or sold"
        );

        listings[_listingId].status = Listing_Status.CANCELLED;
        numberOfListings--;

    }

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

    function cancelOffer(uint256 _listingId, uint256 _offerId) external {
        require(msg.sender == offersPerListing[_listingId][_offerId].offerOwner, "Not offer owner");
        require(offersPerListing[_listingId][_offerId].escrowContract == address(0), "Offer has already been accepted");

        offersPerListing[_listingId][_offerId].offerLength = 0;
    }

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

    function markOfferComplete(uint256 _listingId, uint256 _offerId) external {
        require(msg.sender == offersPerListing[_listingId][_offerId].escrowContract, "Incorrect caller");

        listings[_listingId].status = Listing_Status.SOLD;
        listings[_listingId].winningOffer = _offerId;
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

    function markOfferFailed(uint256 _listingId, uint256 _offerId) external {
        require(msg.sender == offersPerListing[_listingId][_offerId].escrowContract, "Incorrect caller");

        listings[_listingId].status = Listing_Status.LISTED;
        offersPerListing[_listingId][_offerId].accepted = false;
    }

    //Allows ether to be sent to this contract
    receive() external payable {}
}