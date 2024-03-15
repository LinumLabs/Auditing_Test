// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

import "./MobsterNFT.sol";

contract Treasury is Ownable {
    
    // % scaled to 10_000
    uint256 public protocolFee;
    uint256 public monsterHoldersPercentage;

    // it is better to use the address of the contract instead of the address of the interface
    address public mobsterNFT;

    constructor(address _mobsterNFT) Ownable(msg.sender) {
        // need to add validation for _mobsterNFT
        mobsterNFT = _mobsterNFT;
    }

    //Holders array gets sent in from FE

    // problems need to be checked 
    // 1. double loop for holders - is it necessary?
    // 2. magic numbers
    // 3. no validation for _holders array length
    // 4. if _holders.length == 1000 then it will be out of gas
    function distributeRewards(address[] memory _holders) external onlyOwner {
        // use ++x instead of x++ for gas optimization
        for(uint256 x; x < _holders.length; x++) {
            require(MobsterNFT(mobsterNFT).balanceOf(_holders[x]) > 0, "Does not own NFT");
        }

        uint256 contractBalance = address(this).balance;
        // magic numbers
        uint256 monsterHoldersShare = monsterHoldersPercentage * contractBalance / 10000;

        uint256 holderShare;

        if(_holders.length > 0){
            holderShare = monsterHoldersShare / _holders.length;
        }

        // owner should be able to withdraw the protocol fee
        (bool sent, ) = msg.sender.call{value: contractBalance - monsterHoldersShare}("");
        require(sent, "Failed to send Ether");

        for(uint256 x; x < _holders.length; x++) {
            (sent, ) = _holders[x].call{value: holderShare}("");
            require(sent, "Failed to send Ether");
        }

        // after the distribution, the contract should have 0 balance
        // monsterHoldersPercentage should be decresed to 0 after distribution
        // this is a good practice to avoid reentrancy attacks
        // it is also help to avoid the distribution of rewards to holders multiple times or further distribution of rewards
    }

    function setProtocolFee(uint256 _protocolFee) external onlyOwner {
        require(_protocolFee > 0 && _protocolFee <= 10000, "Invalid percentage");
        protocolFee = _protocolFee;
    }

    function setMonsterHolderPercentage(uint256 _monsterHolder) external onlyOwner {
        require(_monsterHolder > 0 && _monsterHolder <= 10000, "Invalid percentage");
        monsterHoldersPercentage = _monsterHolder;
    }

    //Allows ether to be sent to this contract
    receive() external payable {}

}

