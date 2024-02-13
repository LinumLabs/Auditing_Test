// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";

contract CoreTest is Test {

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

    function test_ListSale() public {
        beforeEach();

        assertEq(core.numberOfListings(), 1);
        assertEq(rewardToken.balanceOf(address(alice)), 0);

        vm.startPrank(alice);
        core.listSale("random_uri", 72 ether);
        
        assertEq(core.numberOfListings(), 2);

        (
            uint256 listingId,
            uint256 price,
            uint256 numberOfOffers,
            uint256 winningOffer,
            address ownerOfListing,
            Core.Listing_Status status,
            string memory ipfsHash    
        ) = core.listings(1);

        assertEq(listingId, 1);
        assertEq(price, 72 ether);
        assertEq(numberOfOffers, 0);
        assertEq(winningOffer, 0);
        assertEq(ownerOfListing, address(alice));
        assertEq(uint256(status), 0);
        assertEq(ipfsHash, "random_uri");

        assertEq(rewardToken.balanceOf(address(alice)), 1.8 ether);

        core.listSale("random_uri_2", 12 ether);

        assertEq(rewardToken.balanceOf(address(alice)), 2.1 ether);

        vm.stopPrank();
    }

    function test_CancelListing() public {
        beforeEach();

        vm.startPrank(alice);
        core.listSale("random_uri", 72 ether);

        assertEq(core.numberOfListings(), 2);

        core.cancelListing(1);

        (,,,,, Core.Listing_Status status,) = core.listings(1);

        assertEq(core.numberOfListings(), 1);
        assertEq(uint256(status), 3);
    }

    function test_MakeOffer() public {
        beforeEach();

        vm.prank(alice);
        core.listSale("random_uri", 72 ether);
        
        assertEq(address(core).balance, 0);

        vm.startPrank(bob);
        vm.deal(bob, 100 ether);

        assertEq(rewardToken.balanceOf(address(bob)), 0);

        core.makeOffer{value: 60 ether}(1, 10 days);


        (,, uint256 numberOfOffers ,,,,) = core.listings(1);

        assertEq(numberOfOffers, 1);

        (
            uint256 offerId,
            uint256 listingId,
            uint256 offerAmount,
            uint256 timeOfOffer,
            uint256 offerLength,
            address offerOwner,
            address escrowContract,
            bool accepted
        ) = core.offersPerListing(1, 1);

        assertEq(offerId, 1);
        assertEq(listingId, 1);
        assertEq(offerAmount, 60 ether);
        assertEq(timeOfOffer, 1);
        assertEq(offerLength, 10 days);
        assertEq(offerOwner, address(bob));
        assertEq(escrowContract, address(0));
        assertEq(accepted, false);

        assertEq(address(core).balance, 60 ether);

        assertEq(rewardToken.balanceOf(address(bob)), 0.03 ether);
    }

    function test_CancelOffer() external {
        beforeEach();

        vm.prank(alice);
        core.listSale("random_uri", 72 ether);

        vm.startPrank(bob);
        vm.deal(bob, 100 ether);

        core.makeOffer{value: 60 ether}(1, 10 days);
        assertEq(address(core).balance, 60 ether);

        core.cancelOffer(1, 1);

        (,,,, uint256 offerLength,,,) =  core.offersPerListing(1, 1);

        assertEq(offerLength, 0);
    }

    function test_AcceptOffer() external {

        beforeEach();

        vm.prank(alice);
        core.listSale("random_uri", 72 ether);
        
        vm.prank(bob);
        vm.deal(bob, 100 ether);

        core.makeOffer{value: 60 ether}(1, 10 days);
        assertEq(address(core).balance, 60 ether);

        vm.warp(3 days);

        vm.prank(alice);
        address escrow = core.acceptOffer(1, 1);

        (
            uint256 offerId,
            uint256 listingId,
            uint256 offerAmount,
            uint256 timeOfOffer,
            uint256 offerLength,
            address offerOwner,
            address escrowContract,
            bool accepted
        ) = core.offersPerListing(1, 1);

        assertEq(escrowContract, escrow);
        assertEq(escrow.balance, 60 ether);
        assertEq(address(core).balance, 0 ether);

        Escrow currentEscrow = Escrow(payable(escrow));

        assertEq((currentEscrow).listingId(), 1);
        assertEq((currentEscrow).offerId(), 1);
        assertEq((currentEscrow).sellerAddress(), address(alice));
        assertEq((currentEscrow).buyerAddress(), address(bob));
        assertEq((currentEscrow).coreContract(), address(core));
        assertEq((currentEscrow).treasury(), address(treasury));
        assertEq((currentEscrow).owner(), address(owner));
    }
}
