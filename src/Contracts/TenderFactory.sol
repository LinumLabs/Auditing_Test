// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Tender.sol";

contract TenderFactory {

    address public treasury;
    address public companyContractAddress;

    /**
    ---------------------------------------------------- STATE VARIABLES -------------------------------------------------------------
     */

    mapping(uint256 => address) public tenders;

    uint256 public numberOfTenders;

    /**
    ------------------------------------------------------- CONSTRUCTOR --------------------------------------------------------------
     */

    constructor(address _treasury, address _company) {
        treasury = _treasury;
        companyContractAddress = _company;
    }
    
    /**
    ----------------------------------------------------- PUBLIC FUNCTIONS -----------------------------------------------------------
     */

    /// @notice Government creates the tender for a potential project
    /// @dev A tender is a government project that needs to be awarded and voted on for the future good of the country
    /// @param _duration the length in seconds the tender is open for voting
    /// @param _requiredNumberOfVotes the number of votes needed for the tender to be approved by the public
    /// @param _ipfsHash uri to where the data is being stored on IPFS
    function createTender(uint256 _duration, uint256 _requiredNumberOfVotes, address _tenderAdmin, string memory _ipfsHash) external {        
        require(_duration >= 7 days, "Duration too short");
        Tender newTender = new Tender(_duration, _requiredNumberOfVotes, _tenderAdmin, treasury, companyContractAddress, _ipfsHash);

        tenders[numberOfTenders] = address(newTender);
        numberOfTenders++;
    }

}