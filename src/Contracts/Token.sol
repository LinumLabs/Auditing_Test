// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract Token is ERC20 {

    uint256 public priceOfToken;

    constructor() ERC20("MyToken", "MT") {
        priceOfToken = 0.01 ether;
    }

    function mint(uint256 _amount) external payable {
        require(msg.value == _amount * priceOfToken, "Incorrect Value");
        _mint(msg.sender, _amount);
    }

    function costOfTokens(uint256 _amountOfTokens) external view returns (uint256 cost) {
        cost = _amountOfTokens * priceOfToken;
    }
}