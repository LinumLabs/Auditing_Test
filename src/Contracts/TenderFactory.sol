// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Tender.sol";

contract TenderFactory {

    /**
    ---------------------------------------------------- STATE VARIABLES -------------------------------------------------------------
     */

    mapping(uint256 => address) public tenders;

    uint256 public numberOfTenders;

    /**
    ------------------------------------------------------- CONSTRUCTOR --------------------------------------------------------------
     */

    constructor() {

    }
    
    /**
    ----------------------------------------------------- PUBLIC FUNCTIONS -----------------------------------------------------------
     */

    /// @notice Explain to an end user what this does
    /// @dev Explain to a developer any extra details
    /// @param _duration the length in seconds the tender is open for voting
    /// @param _requiredNumberOfVotes the number of votes needed for the tender to be approved by the public
    /// @param _ipfsHash uri to where the data is being stored on IPFS
    function createTender(uint256 _duration, uint256 _requiredNumberOfVotes, address _tenderAdmin, string memory _ipfsHash) external {        
        Tender newTender = new Tender(_duration, _requiredNumberOfVotes, _tenderAdmin, _ipfsHash);

        tenders[numberOfTenders] = address(newTender);
        numberOfTenders++;
    }

}