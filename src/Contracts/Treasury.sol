// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Treasury is Ownable {
    
    // % scaled to 10_000
    uint256 public protocolFee;
    uint256 public monsterHoldersPercentage;

    constructor() Ownable(msg.sender) {
    }

    //Holders array gets sent in from FE
    function distributeRewards(address[] memory _holders) external onlyOwner {
        uint256 contractBalance = address(this).balance;
        uint256 monsterHoldersShare = monsterHoldersPercentage * contractBalance / 10^18;

        uint256 holderShare = monsterHoldersShare / _holders.length;

        (bool sent, ) = msg.sender.call{value: contractBalance - monsterHoldersShare}("");
        require(sent, "Failed to send Ether");

        for(uint256 x; x < _holders.length; x++) {
            (sent, ) = _holders[x].call{value: holderShare}("");
            require(sent, "Failed to send Ether");
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