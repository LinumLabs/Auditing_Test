// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Main coin information
contract TestUSDC is ERC20 {
    constructor() ERC20("TestUSDC", "TUSDC") {
        _mint(msg.sender, 100000000000000000000000000);
    }

    function mint() public {
        _mint(msg.sender, 100000000000000000000000000);
    }
}
