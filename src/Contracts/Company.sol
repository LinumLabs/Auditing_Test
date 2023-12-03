// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../interfaces/ICompany.sol";


contract Company is ICompany {

    mapping(uint256 => Company) public companies;
    mapping(address => bool) public isCompanyRegistered;

    uint128 public numberOfCompanies;

    //Register a company

    function registerCompany(string memory _ipfsHash, address _wallet) external {
        require(!isCompanyRegistered[msg.sender], "Company already registered");

        companies[numberOfCompanies] = Company({
            companyId: numberOfCompanies,
            companyAdmin: msg.sender,
            companyWallet: _wallet,
            companyUrl: _ipfsHash
        });

        numberOfCompanies++;
    }

    //Pay employee tax to government

    //Add and remove employees

}