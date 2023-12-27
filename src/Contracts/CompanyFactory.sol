// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Company.sol";

contract CompanyFactory {

    /**
    ---------------------------------------------------- STATE VARIABLES -------------------------------------------------------------
     */

    struct CompanyInformation {
        address wallet;
        address admin;
        address contractAddress;
        bool successfullyRegistered;
    }

    uint256 public numberOfCompanies;

    address public governmentAdmin;


    mapping(uint256 => CompanyInformation) public companies;
    mapping(address => bool) public registered;

    /**
    ------------------------------------------------------- CONSTRUCTOR --------------------------------------------------------------
     */

    constructor() {
        governmentAdmin = msg.sender;
    }

    /**
    ----------------------------------------------------- PUBLIC FUNCTIONS -----------------------------------------------------------
     */

    function requestRegistration(address _wallet) public {
        require(!registered[msg.sender], "Already registered");

        companies[numberOfCompanies] = CompanyInformation({
            wallet: _wallet,
            admin: msg.sender,
            contractAddress: address(0),
            successfullyRegistered: false
        });

        numberOfCompanies++;
    }

    function updateAdmin(address _newAdmin) public onlyAdmin {
        governmentAdmin = _newAdmin;
    }


    /**
    ----------------------------------------------- GOVERNMENT OVERRIDE FUNCTIONS -----------------------------------------------------
     */

    function acceptCompanyRegistration(uint256 _companyId) public onlyAdmin {
        companies[_companyId].successfullyRegistered = true;

        Company newCompany = new Company();

        companies[_companyId].contractAddress = address(newCompany);
    }


    /**
    --------------------------------------------------------- MODIFIERS ---------------------------------------------------------------
     */
    
    modifier onlyAdmin() {
        require(msg.sender == governmentAdmin, "Not admin");
        _;
    }



}