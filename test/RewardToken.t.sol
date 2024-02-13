// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";
import "../src/contracts/Core.sol";
import "../src/contracts/Escrow.sol";
import "../src/contracts/MobsterNFT.sol";
import "../src/contracts/RewardToken.sol";

contract RewardTokenTest is Test {

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

    function test_Initialization() public {
        beforeEach();

        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.LISTED_PROPERTY), 250);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.SOLD_PROPERTY), 500);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.MADE_OFFER), 5);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.PURCHASED_PROPERTY), 1000);
    }

    function test_Mint() public {
        beforeEach();

        assertEq(rewardToken.balanceOf(bob), 0);
        rewardToken.mint(RewardToken.Reward_Action.PURCHASED_PROPERTY, 20 ether, bob);
        assertEq(rewardToken.balanceOf(bob), 2 ether);
    }

    function test_SetRewardForAction() public {
        beforeEach();

        vm.prank(owner);
        rewardToken.setRewardForAction(RewardToken.Reward_Action.SOLD_PROPERTY, 5000);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.SOLD_PROPERTY), 5000);
    }

    function test_BatchSetRewardForAction() public {
        beforeEach();

        RewardToken.Reward_Action[] memory actions = new RewardToken.Reward_Action[](4);
        actions[0] = RewardToken.Reward_Action.LISTED_PROPERTY;
        actions[1] = RewardToken.Reward_Action.SOLD_PROPERTY;
        actions[2] = RewardToken.Reward_Action.MADE_OFFER;
        actions[3] = RewardToken.Reward_Action.PURCHASED_PROPERTY;

        uint256[] memory percentages = new uint256[](4);
        percentages[0] = 2000;
        percentages[1] = 3000;
        percentages[2] = 4000;
        percentages[3] = 5000;

        vm.prank(owner);
        rewardToken.batchSetRewardForAction(actions, percentages);

        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.LISTED_PROPERTY), 2000);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.SOLD_PROPERTY), 3000);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.MADE_OFFER), 4000);
        assertEq(rewardToken.rewardPercentagePerAction(RewardToken.Reward_Action.PURCHASED_PROPERTY), 5000);
    }
}
