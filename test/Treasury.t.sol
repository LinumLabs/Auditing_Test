// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Treasury.sol";

contract TreasuryTest is Test {

    Treasury public treasury;

    address owner = vm.addr(1);
    address alice = vm.addr(2);

    function setUp() public {
        treasury = new Treasury();
    }

    function test_withdraw() public {
        
    }  
}
