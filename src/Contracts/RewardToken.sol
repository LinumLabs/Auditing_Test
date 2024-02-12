// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract RewardToken is ERC20, Ownable {

    enum Reward_Action {
        LISTED_PROPERTY,
        SOLD_PROPERTY,
        MADE_OFFER,
        PURCHASED_PROPERTY
    }

    // Percentage of value to be rewarded in tokens, 10_000 being 100%
    mapping(Reward_Action => uint256) public rewardPercentagePerAction;

    constructor() ERC20("RewardToken", "RewT") Ownable(msg.sender) {
        rewardPercentagePerAction[Reward_Action.LISTED_PROPERTY] = 250;
        rewardPercentagePerAction[Reward_Action.SOLD_PROPERTY] = 500;
        rewardPercentagePerAction[Reward_Action.MADE_OFFER] = 5;
        rewardPercentagePerAction[Reward_Action.PURCHASED_PROPERTY] = 1000;
    }

    function mint(Reward_Action _action, uint256 _value, address _recipient) external {
        uint256 mintAmount = _value * rewardPercentagePerAction[_action] / 10000;
        _mint(_recipient, mintAmount);
    }

    function setRewardForAction(Reward_Action _action, uint256 _percentage) external onlyOwner {
        require(_percentage > 0 && _percentage <= 10000, "Invalid percentage");
        rewardPercentagePerAction[_action] = _percentage;
    }

    function batchSetRewardForAction(Reward_Action[] memory _action, uint256[] memory _percentage) external onlyOwner {
        require(_action.length == _percentage.length, "Invalid array lengths");
        
        for(uint256 x; x < _action.length; x++) {
            rewardPercentagePerAction[_action[x]] = _percentage[x];
        }
    }
}