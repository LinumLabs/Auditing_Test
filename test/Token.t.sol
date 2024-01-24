// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/contracts/Token.sol";

contract TokenTest is Test {

    Token public token;

    address owner = vm.addr(1);
    address alice = vm.addr(2);

    function setUp() public {
        token = new Token();
    }

    function test_MintTokens() public {
        vm.startPrank(owner);
        vm.deal(owner, 20 ether);
        vm.expectRevert("Incorrect Value");
        token.mint{value: 5 ether}(100);
        token.mint{value: 1 ether}(100);
    }

    function test_CostOfTokens() public {
        assertEq(token.costOfTokens(100), 1 ether);
        assertEq(token.costOfTokens(1), 0.01 ether);
        assertEq(token.costOfTokens(50000), 500 ether);
        assertEq(token.costOfTokens(47937498), 479374.98 ether);
    }

    
}
