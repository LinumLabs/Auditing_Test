// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "./Escrow.sol";
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
        address owner;
        Listing_Status status;
        string ipfsHash;
    }

    struct Offer {
        uint256 offerId;
        uint256 listingId;
        uint256 offerAmount;
        uint256 offerTime;
        address offerOwner;
        address escrowContract;
        bool accepted;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => mapping(uint256 => Offer)) public offersPerListing;
    mapping(uint256 => uint256) public offersListingId;

    uint256 public numberOfListings = 1;
    uint256 public offerLastingPeriod;

    address public USDC;
    address public treasury;

    constructor(address _USDC, address _treasury) Ownable(msg.sender) {
        USDC = _USDC;
        treasury = _treasury;
    }

    function listSale(string memory _uri, uint256 _price) external {
        listings[numberOfListings] = Listing({
            listingId: numberOfListings,
            price: _price,
            numberOfOffers: 0,
            owner: msg.sender,
            status: Listing_Status.LISTED,
            ipfsHash: _uri
        });

        numberOfListings++;
    }

    function makeOffer(uint256 _listingId, uint256 _offerAmount) external {        
        require(listings[_listingId].listingId != 0, "Listing does not exist");

        uint256 numberOfOffersForListing = listings[_listingId].numberOfOffers;
        offersPerListing[_listingId][numberOfOffersForListing] = Offer({
            offerId: numberOfOffersForListing,
            listingId: _listingId,
            offerAmount: _offerAmount,
            offerTime: block.timestamp,
            offerOwner: msg.sender,
            escrowContract: address(0),
            accepted: false
        });

        offersListingId[numberOfOffersForListing] = _listingId;
        listings[_listingId].numberOfOffers++;
        listings[_listingId].status = Listing_Status.UNDER_OFFER;

        IERC20(USDC).approve(address(this), _offerAmount);
    }

    function acceptOffer(uint256 _offerId) external {
        uint256 listingId = offersListingId[_offerId];
        Offer storage offer = offersPerListing[listingId][_offerId];
        require(msg.sender == listings[listingId].owner, "Not listing owner");
        require(offer.listingId == listingId, "Offer not apart of supplied listing");
        
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



    }

    function markOfferFailed(uint256 _offerId) external {
        uint256 listingId = offersListingId[_offerId];
        require(msg.sender == offersPerListing[listingId][_offerId].escrowContract, "Incorrect caller");

        listings[listingId].status = Listing_Status.LISTED;
    }
}