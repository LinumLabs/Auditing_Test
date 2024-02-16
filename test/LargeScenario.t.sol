// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";
import "../src/contracts/PropertyAuction.sol";

contract LargeScenarioTest is Test {

    Treasury public treasury;
    Core public core;
    MobsterNFT public mobsterNFT;
    RewardToken public rewardToken;

    address owner = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);
    address chad = vm.addr(4);
    address dan = vm.addr(5);
    address elvis = vm.addr(6);
    address greg = vm.addr(7);
    address casey = vm.addr(8);
    address robyn = vm.addr(9);
    address senyo = vm.addr(10);
    address mitch = vm.addr(11);
    
    PropertyAuction public auction;

    function beforeEach() public {
        vm.startPrank(owner);

        rewardToken = new RewardToken();
        mobsterNFT = new MobsterNFT(address(rewardToken));
        treasury = new Treasury(address(mobsterNFT));
        core = new Core(address(treasury), address(rewardToken));
        treasury.setProtocolFee(5000);
        mobsterNFT.setRequiredTokensForMobsterNFT(5 ether);

        vm.deal(owner, 100 ether);
        vm.deal(alice, 100 ether);
        vm.deal(bob, 100 ether);
        vm.deal(chad, 100 ether);
        vm.deal(dan, 100 ether);
        vm.deal(elvis, 100 ether);
        vm.deal(greg, 100 ether);
        vm.deal(casey, 100 ether);
        vm.deal(senyo, 300 ether);
        vm.deal(robyn, 100 ether);
        vm.deal(mitch, 100 ether);


        vm.stopPrank();
    }

    // Multiple standard listings
    // Multiple auctions
    // Multiple giveaways
    // Cancelled listings
    // Cancelled offers
    // NFT minters
    // Treasury distribution
    function test_LargeScenario() public {
        beforeEach();
        
        // Listing 1
        vm.prank(bob);
        core.listSale("Camps Bay, Unit 201", 200 ether);
        assertEq(rewardToken.balanceOf(bob), 5 ether);

        (
            uint256 listingId,
            uint256 price,
            uint256 numberOfOffers,
            address finalBuyer,
            address ownerOfListing, 
            Core.Listing_Status status,
            Core.List_Type typeOfListing,
            string memory hash
        ) = core.listings(1);

        assertEq(listingId, 1);
        assertEq(price, 200 ether);
        assertEq(numberOfOffers, 0);
        assertEq(finalBuyer, address(0));
        assertEq(ownerOfListing, bob);
        assertEq(uint256(status), 0);
        assertEq(uint256(typeOfListing), 0);
        assertEq(hash, "Camps Bay, Unit 201");

        // Listing 2
        vm.prank(alice);
        core.listSale("Beach Apartment, unit 3021", 15 ether);
        assertEq(rewardToken.balanceOf(alice), 0.375 ether);

        // Listing 3
        vm.prank(chad);
        core.listSale("Century Block, unit 56", 5 ether);
        assertEq(rewardToken.balanceOf(chad), 0.125 ether);

        // Listing 4
        vm.prank(alice);
        address auctionOne = core.listSaleForAuction("Beach Apartment, unit 3022", 10 ether, 7 days);
        assertEq(rewardToken.balanceOf(alice), 0.625 ether);

        // Listing 5
        vm.prank(alice);
        core.createGiveaway("Beach Apartment, unit 3023", 0.1 ether);
        assertEq(rewardToken.balanceOf(alice), 0.6275 ether);

        // Listing 6
        vm.prank(dan);
        core.createGiveaway("Studio 7, unit 34", 0.02 ether);
        assertEq(rewardToken.balanceOf(dan), 0.0005 ether);

        // Listing 7
        vm.prank(elvis);
        address auctionTwo = core.listSaleForAuction("Box Studio", 5 ether, 2 days);
        assertEq(rewardToken.balanceOf(elvis), 0.125 ether);

        assertEq(core.numberOfListings(), 8);
        assertEq(rewardToken.totalSupply(), 5.878 ether);

        vm.prank(alice);
        core.cancelListing(5);

        (,,,,, status,,) = core.listings(5);
        assertEq(uint256(status), 3);

        vm.warp(2 days);

        vm.prank(greg);
        core.makeOffer{value: 4.8 ether}(2, 7 days);
        assertEq(address(core).balance, 4.8 ether);
        assertEq(rewardToken.balanceOf(greg), 0.0024 ether);

        vm.prank(elvis);
        core.optIntoGiveaway{value: 0.02 ether}(6);
        assertEq(address(core).balance, 4.82 ether);
        //0.125 ether (creating auction) + 0.00001 ether (optIntoGiveaway)
        assertEq(rewardToken.balanceOf(elvis), 0.12501 ether);

        vm.prank(elvis);
        core.makeOffer{value: 4.9 ether}(2, 3 days);
        assertEq(address(core).balance, 9.72 ether);
        //0.125 ether (creating auction) + 0.00001 ether (optIntoGiveaway) + 0.00245 (make offer)
        assertEq(rewardToken.balanceOf(elvis), 0.12746 ether);

        vm.prank(dan);
        PropertyAuction(auctionOne).bidWithETH{value: 11 ether}();
        assertEq(auctionOne.balance, 11 ether);
        //0.0005 ether (creating giveaway) + 0.0055 ether (bid on auction)
        assertEq(rewardToken.balanceOf(dan), 0.006 ether);

        vm.prank(greg);
        core.optIntoGiveaway{value: 0.02 ether}(6);
        assertEq(address(core).balance, 9.74 ether);
        //0.0024 ether (making offer) + 0.00001 ether (opting into giveaway)
        assertEq(rewardToken.balanceOf(greg), 0.00241 ether);

        vm.warp(2 days);

        vm.prank(mitch);
        core.createGiveaway("Seaside unit 5", 3 ether);
        assertEq(rewardToken.balanceOf(mitch), 0.075 ether);

        vm.prank(casey);
        PropertyAuction(auctionOne).bidWithETH{value: 15 ether}();
        assertEq(auctionOne.balance, 26 ether);
        assertEq(PropertyAuction(auctionOne).userCredit(dan), 11 ether);
        assertEq(rewardToken.balanceOf(casey), 0.0075 ether);

        vm.prank(dan);
        PropertyAuction(auctionTwo).bidWithETH{value: 5.1 ether}();
        assertEq(auctionTwo.balance, 5.1 ether);
        //0.0005 ether (creating giveaway) + 0.0055 ether (bid on auction) + 0.00255 ether (bid on auction)
        assertEq(rewardToken.balanceOf(dan), 0.00855 ether);

        vm.prank(robyn);
        core.optIntoGiveaway{value: 0.02 ether}(6);
        assertEq(address(core).balance, 9.76 ether);
        assertEq(rewardToken.balanceOf(robyn), 0.00001 ether);

        vm.startPrank(greg);
        core.cancelOffer(2, 1);
        assertEq(core.userCredit(greg), 4.8 ether);

        core.withdrawFunds(4.8 ether);
        assertEq(address(core).balance, 4.96 ether);
        assertEq(core.userCredit(greg), 0 ether);
        vm.stopPrank();

        vm.prank(senyo);
        core.makeOffer{value: 190 ether}(1, 12 days);
        assertEq(address(core).balance, 194.96 ether);
        assertEq(rewardToken.balanceOf(senyo), 0.095 ether);

        assertEq(rewardToken.totalSupply(), 6.06843 ether);








    }
}
