// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Treasury is Ownable {

    uint256 public fee;

    constructor() Ownable(msg.sender) {

    }

    function withdrawFunds() external onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    //Allows ether to be sent to this contract
    receive() external payable {}

}