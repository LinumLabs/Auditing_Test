// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

//import "../../lib/openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import "@openzeppelin/contracts/access/Ownable2Step.sol";
import "../interfaces/ICompany.sol";
import "./Company.sol";

contract CompanyFactory is ICompany {

    mapping(uint256 => address) public companyAddresses;
    mapping(address => bool) public isCompanyRegistered;

    uint128 public numberOfCompanies;

    event CompanyRegistered(uint128 companyId);

    constructor() public {
        
    }

    function registerCompany(string memory _ipfsHash) external {
        require(!isCompanyRegistered[msg.sender], "Company already registered");

        Company newCompany = new Company(msg.sender, _ipfsHash);
        companyAddresses[numberOfCompanies] = address(newCompany);

        isCompanyRegistered[msg.sender] = true;

        emit CompanyRegistered(numberOfCompanies);

        unchecked {
            numberOfCompanies++;
        }
    }
}