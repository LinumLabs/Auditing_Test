// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Treasury {

    address public usdc;

    /**
    ---------------------------------------------------- STATE VARIABLES -------------------------------------------------------------
     */


    /**
    ------------------------------------------------------- CONSTRUCTOR --------------------------------------------------------------
     */

    constructor(address _usdc) {
        usdc = _usdc;
    }

    /**
    ----------------------------------------------------- PUBLIC FUNCTIONS -----------------------------------------------------------
     */

    function fundProject(uint256 _fundingAmount, address _projectAddress) public {
        IERC20(usdc).transfer(_projectAddress, _fundingAmount);
    }


    /**
    ----------------------------------------------- GOVERNMENT OVERRIDE FUNCTIONS -----------------------------------------------------
     */


    /**
    --------------------------------------------------------- MODIFIERS ---------------------------------------------------------------
     */



}