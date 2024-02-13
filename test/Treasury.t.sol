// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";

contract TreasuryTest is Test {

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

        rewardToken = new RewardToken();
        mobsterNFT = new MobsterNFT(address(rewardToken));
        treasury = new Treasury(address(mobsterNFT));
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
        address escrow = core.acceptOffer(1, 1);

        currentEscrow = Escrow(payable(escrow));

        vm.prank(owner);
        currentEscrow.completeSale();
    }

    function test_SetProtocolFee() public {
        beforeEach();

        assertEq(treasury.protocolFee(), 5000);
        vm.prank(owner);
        treasury.setProtocolFee(2000);
        assertEq(treasury.protocolFee(), 2000);
    }

    function test_SetMonsterHolderPercentage() public {
        beforeEach();

        assertEq(treasury.monsterHoldersPercentage(), 0);
        vm.prank(owner);
        treasury.setMonsterHolderPercentage(2000);
        assertEq(treasury.monsterHoldersPercentage(), 2000);
    }

    function test_DistributeRewards() public {
        beforeEach();

        vm.startPrank(owner);
        treasury.setMonsterHolderPercentage(2000);
        mobsterNFT.setRequiredTokensForMobsterNFT(5 ether);
        vm.stopPrank();

        assertEq(address(treasury).balance, 30 ether);

        address[] memory holders = new address[](3);
        holders[0] = bob;
        holders[1] = chad;
        holders[2] = dan;

        vm.startPrank(bob);
        rewardToken.mint(RewardToken.Reward_Action.PURCHASED_PROPERTY, 51 ether, bob);
        rewardToken.approve(address(mobsterNFT), mobsterNFT.requiredTokensForMobsterNFT());
        mobsterNFT.claimNft();
        vm.stopPrank();

        vm.startPrank(chad);
        rewardToken.mint(RewardToken.Reward_Action.PURCHASED_PROPERTY, 51 ether, chad);
        rewardToken.approve(address(mobsterNFT), mobsterNFT.requiredTokensForMobsterNFT());
        mobsterNFT.claimNft();
        vm.stopPrank();

        vm.startPrank(dan);
        rewardToken.mint(RewardToken.Reward_Action.PURCHASED_PROPERTY, 51 ether, dan);
        rewardToken.approve(address(mobsterNFT), mobsterNFT.requiredTokensForMobsterNFT());
        mobsterNFT.claimNft();
        vm.stopPrank();

        vm.prank(owner);
        treasury.distributeRewards(holders);

        assertEq(address(treasury).balance, 0 ether);
        assertEq(owner.balance, 24 ether);
        assertEq(bob.balance, 42 ether);
        assertEq(chad.balance, 2 ether);
        assertEq(dan.balance, 2 ether);
    }
}
