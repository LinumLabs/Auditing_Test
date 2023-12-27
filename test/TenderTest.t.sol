// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/Contracts/TenderFactory.sol";
import "../src/Contracts/Tender.sol";
import "../src/Contracts/Treasury.sol";
import "../src/Contracts/TestUSDC.sol";
import "../src/Contracts/Project.sol";
import "../src/Contracts/CompanyFactory.sol";

contract TenderTest is Test {

    address admin = vm.addr(1);
    address alice = vm.addr(2);
    address bob = vm.addr(3);
    address companyAdmin = vm.addr(5);
    address companyWallet = vm.addr(6);

    uint256 desiredTimestamp = 200;
    uint256 tenderDuration = 8 days;
    uint256 numberOfRequiredVotes = 100;
    string ipfsHash = "TestHash";

    TenderFactory public tenderFactory;
    Tender public tenderInstance;
    Treasury public treasury;
    TestUSDC public usdc;
    CompanyFactory public companyFactory;

    function setUp() public {
        vm.startPrank(admin);
        usdc = new TestUSDC();
        companyFactory = new CompanyFactory();
        treasury = new Treasury(address(usdc));
        tenderFactory = new TenderFactory(address(treasury), address(companyFactory));
        vm.stopPrank();

        vm.prank(address(treasury));
        usdc.mint();

        vm.warp(desiredTimestamp);
        vm.prank(admin);
        tenderFactory.createTender(tenderDuration, numberOfRequiredVotes, address(admin), ipfsHash);

        address tenderAddress = tenderFactory.tenders(0);

        tenderInstance = Tender(tenderAddress);

        vm.prank(companyAdmin);
        companyFactory.requestRegistration(address(companyWallet));

        vm.prank(admin);
        companyFactory.acceptCompanyRegistration(0);
    }

    function test_TenderInstanceInstantiatedCorrectly() public {
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

    function test_FundsGetDepositedToNewProject() public {
        vm.startPrank(admin);
        tenderInstance.overrideAndApprove();
        tenderInstance.openTenderForProposals();
        vm.stopPrank();

        vm.prank(companyAdmin);
        tenderInstance.propose("TestUri", 0);

        vm.prank(admin);
        tenderInstance.closeProposingAndOpenVoting();

        vm.prank(alice);
        tenderInstance.voteForProposal(0);

        vm.startPrank(admin);
        tenderInstance.closeProposalVoting();
        tenderInstance.awardProposal(1000);
        
        address projectInstance = tenderInstance.winningProposalContract();

        assertEq(usdc.balanceOf(address(projectInstance)), 1000);
    }
}
