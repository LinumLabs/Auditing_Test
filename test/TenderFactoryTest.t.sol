// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Contracts/TenderFactory.sol";
import "../src/Contracts/Tender.sol";
import "../src/Contracts/Treasury.sol";
import "../src/Contracts/TestUSDC.sol";
import "../src/Contracts/Company.sol";

contract TenderFactoryTest is Test {

    address admin = vm.addr(1);
    address alice = vm.addr(2);

    TenderFactory public tenderFactory;
    Treasury public treasury;
    TestUSDC public usdc;
    Company public company;


    function setUp() public {
        usdc = new TestUSDC();
        company = new Company();
        treasury = new Treasury(address(usdc));
        tenderFactory = new TenderFactory(address(treasury), address(company));
        company = new Company();
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
        assertEq(Tender(tenderAddress).closingDateForVoting(), tenderDuration + desiredTimestamp);
    }
}
