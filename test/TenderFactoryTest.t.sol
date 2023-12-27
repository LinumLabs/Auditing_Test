// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Contracts/TenderFactory.sol";
import "../src/Contracts/Tender.sol";

contract TenderFactoryTest is Test {

    address admin = vm.addr(1);
    address alice = vm.addr(2);

    TenderFactory public tenderFactory;

    function setUp() public {
        tenderFactory = new TenderFactory();
    }

    function test_CreateTenderFailsIfInvalidLength() public {

        uint256 tenderDuration = 6 days;
        uint256 numberOfRequiredVotes = 100;
        string memory ipfsHash = "TestHash";

        vm.expectRevert("Duration too short");
        vm.prank(admin);
        tenderFactory.createTender(tenderDuration, numberOfRequiredVotes, address(admin), ipfsHash);
    }

    function test_TenderCreation() public {

        uint256 desiredTimestamp = 200;
        uint256 tenderDuration = 8 days;
        uint256 numberOfRequiredVotes = 100;
        string memory ipfsHash = "TestHash";

        vm.warp(desiredTimestamp);
        vm.prank(admin);
        tenderFactory.createTender(tenderDuration, numberOfRequiredVotes, address(admin), ipfsHash);

        address tenderAddress = tenderFactory.tenders(0);

        assertEq(tenderFactory.numberOfTenders(), 1);

        assertEq(Tender(tenderAddress).creationTime(), desiredTimestamp);
        assertEq(Tender(tenderAddress).closingDateForVoting(), tenderDuration + desiredTimestamp);



    }
}
