// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Treasury is Ownable {
    
    address public USDC;

    // % scaled to 10_000
    uint256 public protocolFee;
    uint256 public monsterHoldersPercentage;

    constructor(address _USDC) Ownable(msg.sender) {
        USDC = _USDC;
    }

    //Holders array gets sent in from FE
    function distributeRewards(address[] memory _holders) external onlyOwner {
        uint256 contractBalance = IERC20(USDC).balanceOf(address(this));
        uint256 monsterHoldersShare = monsterHoldersPercentage * contractBalance / 10000;

        uint256 holderShare = monsterHoldersShare / _holders.length;

        IERC20(USDC).transfer(msg.sender, contractBalance - monsterHoldersShare);

        for(uint256 x; x < _holders.length; x++) {
            IERC20(USDC).transfer(_holders[x], holderShare);
        }
    }

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        require(_protocolFee > 0 || _protocolFee <= 10000, "Invalid percentage");
        protocolFee = _protocolFee;
    }

    function setMonsterHolderPercentage(uint256 _monsterHolder) external onlyOwner {
        require(_monsterHolder > 0 || _monsterHolder <= 10000, "Invalid percentage");
        monsterHoldersPercentage = _monsterHolder;
    }

    //Allows ether to be sent to this contract
    receive() external payable {}

}