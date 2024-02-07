// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Escrow.sol";
import "./RewardToken.sol";

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
    mapping(uint256 => uint256) public offersListingId;

    uint256 public numberOfListings = 1;

    address public USDC;
    address public treasury;
    address public rewardToken;

    constructor(address _USDC, address _treasury, address _rewardToken) Ownable(msg.sender) {
        USDC = _USDC;
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

    function cancelListing(uint256 _listingId) external {
        require(msg.sender == listings[_listingId].owner, "Not listing creator");

        listings[_listingId].status = Listing_Status.CANCELLED;

    }

    function makeOffer(uint256 _listingId, uint256 _offerAmount, uint256 _offerLength) external {        
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
            offerAmount: _offerAmount,
            timeOfOffer: block.timestamp,
            offerLength: _offerLength,
            offerOwner: msg.sender,
            escrowContract: address(0),
            accepted: false
        });

        offersListingId[numberOfOffersForListing] = _listingId;
        listings[_listingId].status = Listing_Status.UNDER_OFFER;

        IERC20(USDC).approve(address(this), _offerAmount);
        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.MADE_OFFER, 
            _offerAmount, 
            msg.sender
        );
    }

    function acceptOffer(uint256 _offerId) external {
        uint256 listingId = offersListingId[_offerId];
        Offer storage offer = offersPerListing[listingId][_offerId];
        require(msg.sender == listings[listingId].owner, "Not listing owner");
        require(
            listings[listingId].status == Listing_Status.LISTED || 
            listings[listingId].status == Listing_Status.UNDER_OFFER, 
            "Listing cancelled or sold"
        );
        require(offer.listingId == listingId, "Offer not apart of supplied listing");
        require(block.timestamp <= offer.timeOfOffer + offer.offerLength, "Offer has run out");

        Escrow escrowContract = new Escrow(
            listingId, 
            _offerId, 
            owner(), 
            listings[listingId].owner, 
            offersPerListing[listingId][_offerId].offerOwner, 
            USDC, 
            address(this),
            treasury
        );

        IERC20(USDC).transferFrom(offer.offerOwner, address(escrowContract), offer.offerAmount);
    }

    function markOfferComplete(uint256 _offerId) external {
        uint256 listingId = offersListingId[_offerId];
        require(msg.sender == offersPerListing[listingId][_offerId].escrowContract, "Incorrect caller");

        offersPerListing[listingId][_offerId].accepted = true;
        listings[listingId].status = Listing_Status.SOLD;
        
        listings[listingId].winningOffer = _offerId;

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.SOLD_PROPERTY, 
            offersPerListing[listingId][_offerId].offerAmount, 
            listings[listingId].owner
        );

        RewardToken(rewardToken).mint(
            RewardToken.Reward_Action.PURCHASED_PROPERTY, 
            offersPerListing[listingId][_offerId].offerAmount, 
            offersPerListing[listingId][_offerId].offerOwner
        );
    }

    function markOfferFailed(uint256 _offerId) external {
        uint256 listingId = offersListingId[_offerId];
        require(msg.sender == offersPerListing[listingId][_offerId].escrowContract, "Incorrect caller");

        listings[listingId].status = Listing_Status.LISTED;
    }
}