// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Contracts/TenderFactory.sol";
import "../src/Contracts/Tender.sol";

contract TenderTest is Test {

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(2);

    uint256 desiredTimestamp = 200;
    uint256 tenderDuration = 8 days;
    uint256 numberOfRequiredVotes = 100;
    string ipfsHash = "TestHash";

    TenderFactory public tenderFactory;
    Tender public tenderInstance;

    function setUp() public {
        tenderFactory = new TenderFactory();

        vm.warp(desiredTimestamp);
        vm.prank(admin);
        tenderFactory.createTender(tenderDuration, numberOfRequiredVotes, address(admin), ipfsHash);

        address tenderAddress = tenderFactory.tenders(0);

        tenderInstance = Tender(tenderAddress);
    }

    function test_TenderInstanceInstantiatedCorrectly() public {
        assertEq(tenderInstance.creationTime(), desiredTimestamp);
        assertEq(tenderInstance.closingDateForVoting(), desiredTimestamp + tenderDuration);
        assertEq(tenderInstance.numberOfYesVotes(), 0);
        assertEq(tenderInstance.requiredNumberOfVotes(), numberOfRequiredVotes);
        assertEq(tenderInstance.ipfsHash(), ipfsHash);
    }

    function test_YesVoteFailsIfAlreadyVoted() public {
        vm.prank(alice);
        tenderInstance.yesVote();

        assertEq(tenderInstance.numberOfYesVotes(), 1);

        vm.expectRevert("Already voted");
        vm.prank(alice);
        tenderInstance.yesVote();
    }

    function test_YesVoteFailsIfVotingComplete() public {
        vm.prank(alice);
        tenderInstance.yesVote();

        assertEq(tenderInstance.numberOfYesVotes(), 1);

        vm.prank(admin);
        tenderInstance.overrideAndApprove();

        vm.expectRevert("Voting complete");
        vm.prank(bob);
        tenderInstance.yesVote();
    }
}
