// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface ICompany {
    
    struct CompanyDetails {
        uint256 companyId;
        address companyAdmin;
        address companyContractAddress;
        string companyUrl;
    }
}
