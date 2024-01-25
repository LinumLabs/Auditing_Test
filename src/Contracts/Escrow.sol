// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract Core is Ownable {


    constructor() Ownable(msg.sender) {
    }

    
}