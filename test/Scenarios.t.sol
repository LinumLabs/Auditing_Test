// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";

contract ScenariosTest is Test {

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

    function beforeEach() public {
        vm.startPrank(owner);

        rewardToken = new RewardToken();
        mobsterNFT = new MobsterNFT(address(rewardToken));
        treasury = new Treasury(address(mobsterNFT));
        core = new Core(address(treasury), address(rewardToken));

        vm.stopPrank();
    }

    // 3 Listings
    // 3 offers
    // 1 purchase
    function test_ScenarioOne() public {
        beforeEach();

        // Dependencies
        vm.startPrank(owner);
        mobsterNFT.setRequiredTokensForMobsterNFT(5 ether);
        treasury.setProtocolFee(5000);
        vm.stopPrank();

        // 2 Listings
        vm.prank(bob);
        core.listSale("Bob_Listing_One", 125 ether);

        vm.prank(alice);
        core.listSale("Alice_Listing_One", 25 ether);

        assertEq(core.numberOfListings(), 3);
        assertEq(rewardToken.balanceOf(bob), 3.125 ether);
        assertEq(rewardToken.balanceOf(alice), 0.625 ether);

        // 3 Offers
        vm.prank(chad);
        vm.deal(chad, 100 ether);
        core.makeOffer{value: 100 ether}(1, 7 days);

        vm.prank(dan);
        vm.deal(dan, 100 ether);
        core.makeOffer{value: 23 ether}(2, 7 days);

        vm.prank(elvis);
        vm.deal(elvis, 100 ether);
        core.makeOffer{value: 24 ether}(2, 10 days);

        assertEq(rewardToken.balanceOf(chad), 0.05 ether);
        assertEq(rewardToken.balanceOf(dan), 0.0115 ether);
        assertEq(rewardToken.balanceOf(elvis), 0.012 ether);
        assertEq(address(core).balance, 147 ether);

        // Acceptance
        vm.prank(alice);
        address escrowContract = core.acceptOffer(2, 2);

        assertEq(escrowContract.balance, 24 ether);
        assertEq(address(core).balance, 123 ether);

        // Complete Sale
        vm.prank(owner);
        Escrow(payable(escrowContract)).completeSale();

        assertEq(address(treasury).balance, 12 ether);
        assertEq(alice.balance, 12 ether);

        address[] memory holders = new address[](0);

        vm.prank(owner);
        treasury.distributeRewards(holders);

        assertEq(owner.balance, 12 ether);
        assertEq(rewardToken.balanceOf(alice), 1.825 ether);
        assertEq(rewardToken.balanceOf(elvis), 2.412 ether);



    }
}
