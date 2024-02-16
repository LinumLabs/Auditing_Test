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
        treasury.setMonsterHolderPercentage(2000);
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

    // --------------------------------------------------------------------------------------------------------------------
    // -------------------------------------------- CREATING LISTINGS -----------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------
        
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

    // --------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------ BIDDING ON LISTINGS -----------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

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

    // --------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------ COMPLETING LISTINGS -----------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

        vm.prank(alice);
        address escrowOfferOne = core.acceptOffer(2, 1);
        assertEq(escrowOfferOne.balance, 4.8 ether);
        assertEq(address(core).balance, 190.16 ether);

        uint256 gregInitialBalance = greg.balance;

        vm.prank(owner);
        Escrow(payable(escrowOfferOne)).rejectSale();
        assertEq(escrowOfferOne.balance, 0 ether);
        assertEq(address(core).balance, 190.16 ether);
        assertEq(address(greg).balance, gregInitialBalance + 4.8 ether);

        vm.prank(alice);
        address escrowTwo = core.acceptOffer(2, 2);
        assertEq(escrowTwo.balance, 4.9 ether);
        assertEq(address(core).balance, 185.26 ether);

        uint256 aliceInitialBalance = alice.balance;

        vm.prank(owner);
        Escrow(payable(escrowTwo)).completeSale();
        assertEq(escrowOfferOne.balance, 0 ether);
        assertEq(address(treasury).balance, 2.45 ether);
        assertEq(address(alice).balance, aliceInitialBalance + 2.45 ether);
        // 0.6275 ether (creating listings) + 0.245 (selling a property) 
        assertEq(rewardToken.balanceOf(alice), 0.8725 ether);
        // 0.12746 ether (previous interactions) + 0.49 (buying a property) 
        assertEq(rewardToken.balanceOf(elvis), 0.61746 ether);

        vm.warp(29 days);

        vm.prank(dan);
        address winner = core.closeGiveaway(6);

        (,,, finalBuyer,,,,) = core.listings(6);

        if(winner == elvis) {
            assertEq(finalBuyer, elvis);
            // 0.61746 ether (after buying property) + 0.002 ether (winning giveaway)
            assertEq(rewardToken.balanceOf(elvis), 0.61946 ether);
        } else if(winner == greg) {
            assertEq(finalBuyer, greg);
            // 0.00241 ether (making offers) + 0.002 ether (winning giveaway)
            assertEq(rewardToken.balanceOf(greg), 0.00441 ether);
        } else if(winner == robyn) {
            assertEq(finalBuyer, robyn);
            // 0.00001 ether (opting into giveaway) + 0.002 ether (winning giveaway)
            assertEq(rewardToken.balanceOf(robyn), 0.00201 ether);
        }

        // 0.00855 ether (previous interactions) + 0.001 ether (donating giveaway)
        assertEq(rewardToken.balanceOf(dan), 0.00955 ether);
        assertEq(address(treasury).balance, 2.48 ether);
        assertEq(core.userCredit(dan), 0.03 ether);

        vm.startPrank(alice);
        PropertyAuction(auctionOne).closeAuction();
        vm.warp(37 days);
        PropertyAuction(auctionOne).settleAuction();
        vm.stopPrank();

        assertEq(address(treasury).balance, 9.98 ether);
        assertEq(auctionOne.balance, 18.5 ether);
        assertEq(PropertyAuction(auctionOne).userCredit(alice), 7.5 ether);
        // 0.8725 ether (previous interactions) + 0.75 ether (selling property)
        assertEq(rewardToken.balanceOf(alice), 1.6225 ether);
        // 0.0075 ether (previous interactions) + 1.5 ether (selling property)
        assertEq(rewardToken.balanceOf(casey), 1.5075 ether);

    // --------------------------------------------------------------------------------------------------------------------
    // ------------------------------------------------- CLAIMING NFT -----------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

        vm.startPrank(bob);
        assertEq(mobsterNFT.balanceOf(bob), 0);
        assertEq(rewardToken.balanceOf(bob), 5 ether);
        rewardToken.approve(address(mobsterNFT), 5 ether);
        mobsterNFT.claimNft();
        assertEq(mobsterNFT.balanceOf(bob), 1);
        assertEq(rewardToken.balanceOf(bob), 0 ether);
        vm.stopPrank();
       
    // --------------------------------------------------------------------------------------------------------------------
    // --------------------------------------------- TREASURY DISTRIBUTION ------------------------------------------------
    // --------------------------------------------------------------------------------------------------------------------

        address[] memory holders = new address[](1);
        holders[0] = bob;

        uint256 bobBalanceBeforeDistribution = bob.balance;
        uint256 ownerBalanceBeforeDistribution = owner.balance;

        vm.prank(owner);
        treasury.distributeRewards(holders);
        assertEq(address(treasury).balance, 0 ether);
        assertEq(bob.balance, bobBalanceBeforeDistribution + 1.996 ether);
        assertEq(owner.balance, ownerBalanceBeforeDistribution + 7.984 ether);
    }
}
