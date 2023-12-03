// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


contract Company {

    address public admin;
    string public ipfsHash;

    constructor(address _admin, string memory _ipfsHash) public {
        admin = _admin;
        ipfsHash = _ipfsHash;
    }

    //Pay employee tax

    //Add and remove employees

    //Update employee information

}