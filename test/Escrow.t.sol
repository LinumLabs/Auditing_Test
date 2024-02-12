// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";

contract EscrowTest is Test {

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

    Escrow public currentEscrow;

    function beforeEach() public {
        vm.startPrank(owner);

        treasury = new Treasury();
        rewardToken = new RewardToken();
        mobsterNFT = new MobsterNFT(address(rewardToken));
        core = new Core(address(treasury), address(rewardToken));

        treasury.setProtocolFee(5000);

        vm.stopPrank();

        vm.prank(alice);
        core.listSale("random_uri", 72 ether);
        
        vm.prank(bob);
        vm.deal(bob, 100 ether);

        core.makeOffer{value: 60 ether}(1, 10 days);
        assertEq(address(core).balance, 60 ether);

        vm.warp(3 days);

        vm.prank(alice);
        address escrow = core.acceptOffer(1);

        currentEscrow = Escrow(payable(escrow));
    }

    function test_CompleteSale() public {
        beforeEach();

        assertEq(address(currentEscrow).balance, 60 ether);

        vm.prank(owner);
        currentEscrow.completeSale();

        (,,, uint256 winningOffer,, Core.Listing_Status status,) = core.listings(1);

        assertEq(winningOffer, 1);
        assertEq(uint256(status), 2);

        assertEq(address(currentEscrow).balance, 0 ether);
        assertEq(address(treasury).balance, 30 ether);

        assertEq(rewardToken.balanceOf(address(alice)), 4.8 ether);
        assertEq(rewardToken.balanceOf(address(bob)), 6.03 ether);
    }

    function test_RejectSale() public {
        beforeEach();

        assertEq(address(currentEscrow).balance, 60 ether);
        assertEq(address(core).balance, 0 ether);

        vm.prank(owner);
        currentEscrow.rejectSale();

        (,,,,, Core.Listing_Status status,) = core.listings(1);
        (,,,,,,, bool accepted) = core.offersPerListing(1,1);

        assertEq(accepted, false);
        assertEq(uint256(status), 0);

        assertEq(address(currentEscrow).balance, 0 ether);
        assertEq(address(core).balance, 60 ether);
    }
}
