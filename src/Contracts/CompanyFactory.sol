// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../interfaces/ICompany.sol";
import "./Company.sol";


contract CompanyFactory is ICompany {

    mapping(uint256 => Company) public companies;
    mapping(address => bool) public isCompanyRegistered;

    uint128 public numberOfCompanies;

    constructor() public {
        
    }

    //Register a company
    function registerCompany(string memory _ipfsHash) external {
        require(!isCompanyRegistered[msg.sender], "Company already registered");

        Company newCompany = new Company();

        companies[numberOfCompanies] = Company({
            companyId: numberOfCompanies,
            companyAdmin: msg.sender,
            companyContractAddress: address(newCompany),
            companyUrl: _ipfsHash
        });

        numberOfCompanies++;
    }
}