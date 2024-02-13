// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";

contract MobsterNFTTest is Test {

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

    function test_ClaimNFT() public {
        beforeEach();

        vm.prank(owner);
        mobsterNFT.setRequiredTokensForMobsterNFT(5 ether);

        vm.startPrank(bob);
        rewardToken.mint(RewardToken.Reward_Action.PURCHASED_PROPERTY, 51 ether, bob);

        assertEq(mobsterNFT.balanceOf(bob), 0);

        rewardToken.approve(address(mobsterNFT), mobsterNFT.requiredTokensForMobsterNFT());
        mobsterNFT.claimNft();

        assertEq(mobsterNFT.balanceOf(bob), 1);
    }
}
