// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Core is Ownable {

    enum Listing_Status {
        LISTED,
        UNDER_OFFER,
        SOLD,
        CANCELLED
    }

    struct Listing {
        address agent;
        uint256 listingId;
        uint256 price;
        uint256 numberOfOffers;
        Listing_Status status;
        string ipfsHash;
    }

    struct Offer {
        uint256 offerId;
        uint256 listingId;
        uint256 offerAmount;
        uint256 offerTime;
        bool accepted;
    }

    mapping(uint256 => Listing) public listings;
    mapping(uint256 => mapping(uint256 => Offer)) public offersPerListing;

    uint256 public numberOfListings;
    uint256 public offerLastingPeriod;

    constructor() Ownable(msg.sender) {
    }

    function listSale(string memory _uri, uint256 _price) external {
        listings[numberOfListings] = Listing({
            agent: msg.sender,
            listingId: numberOfListings,
            price: _price,
            numberOfOffers: 0,
            status: Listing_Status.LISTED,
            ipfsHash: _uri
        });
    }

    function makeOffer(uint256 _listingId, uint256 _offerAmount) external {
        offersPerListing[_listingId][listings[_listingId].numberOfOffers] = Offer({
            offerId: listings[_listingId].numberOfOffers,
            listingId: _listingId,
            offerAmount: _offerAmount,
            offerTime: block.timestamp,
            accepted: false
        });
    }


}