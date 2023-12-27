// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "./Project.sol";

contract Tender {

    /**
    ---------------------------------------------------- STATE VARIABLES -------------------------------------------------------------
     */

    struct Proposal {
        uint256 numberOfVotes;
        string uri;
    }

    enum TenderState {
        VOTING,
        APPROVED,
        DECLINED,
        PROPOSING,
        PROPOSAL_VOTING,
        AWARDED
    }

    uint256 public closingDateForVoting;
    uint256 public numberOfYesVotes;
    uint256 public requiredNumberOfVotes;
    uint256 public numberOfProposals;
    uint256 public currentWinningProposal;
    uint256 public winningProposal;

    address public tenderAdmin;
    address public winningProposalContract;

    string public ipfsHash;

    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) private yesVoted;
    mapping(address => mapping(uint256 => bool)) private votedForProposal;

    TenderState public tenderState;

    /**
    ------------------------------------------------------- CONSTRUCTOR --------------------------------------------------------------
     */

    constructor(uint256 _duration, uint256 _requiredNumberOfVotes, address _tenderAdmin, string memory _ipfsHash) {
        closingDateForVoting = block.timestamp + _duration;
        tenderState = TenderState.VOTING;
        requiredNumberOfVotes = _requiredNumberOfVotes;
        ipfsHash = _ipfsHash;
        tenderAdmin = _tenderAdmin;
    }

    /**
    ----------------------------------------------------- PUBLIC FUNCTIONS -----------------------------------------------------------
     */

    /// @notice Users yes vote if they believe in the tender and would like to see it be approved
    /// @dev Users can vote only once while voting is open to try reach the required approved votes to approve the tender.
    ///      Approved tenders simply means the tender has moved to the proposal stage, allowing companies to bid for the right
    ///      to be awarded the tender.
    function yesVote() public {
        require(tenderState == TenderState.VOTING, "Voting complete");
        require(yesVoted[msg.sender] == false, "Already voted");
        require(tenderState == TenderState.VOTING, "Voting complete");
        require(block.timestamp <= closingDateForVoting, "Voting complete");

        numberOfYesVotes++;

        yesVoted[msg.sender] = true;

        if(numberOfYesVotes == requiredNumberOfVotes) {
            tenderState = TenderState.APPROVED;
        }
    }

    /// @notice Users can propose to fullfil the tender
    /// @dev Anyone can propose but must have all their documents and details on IPFS for voters to be able to view
    /// @param _uri the link the IPFS where all the data around the proposal is stored
    function propose(string memory _uri) public {
        require(tenderState == TenderState.PROPOSING, "Not open to proposals");
        proposals[numberOfProposals] = Proposal({
            numberOfVotes: 0,
            uri: _uri
        });

        numberOfProposals++;
    }

    /// @notice Users can vote for a proposal to help it get awarded
    /// @dev Users can only vote once for a proposal
    /// @param _proposalId the ID of the proposal to vote for
    function voteForProposal(uint256 _proposalId) public {
        require(tenderState == TenderState.PROPOSAL_VOTING, "Not open to proposal voting");
        require(votedForProposal[msg.sender][_proposalId] == false, "Already voted for proposal");

        proposals[_proposalId].numberOfVotes++;
        votedForProposal[msg.sender][_proposalId] = true;

        if(proposals[_proposalId].numberOfVotes > proposals[currentWinningProposal].numberOfVotes) {
            currentWinningProposal = _proposalId;
        }
    }

    /**
    ----------------------------------------------- GOVERNMENT OVERRIDE FUNCTIONS -----------------------------------------------------
     */

    function overrideAndApprove() public onlyAdmin {
        require(tenderState == TenderState.VOTING || tenderState == TenderState.DECLINED, "Invalid phase");

        tenderState = TenderState.APPROVED;

    } 

    function overrideAndDecline() public onlyAdmin {
        require(tenderState == TenderState.VOTING || tenderState == TenderState.APPROVED, "Invalid phase");

        tenderState = TenderState.DECLINED;

    }

    function openTenderForProposals() public onlyAdmin {
        require(tenderState == TenderState.APPROVED, "Tender not in approved state");

        tenderState = TenderState.PROPOSING;
    }

    function closeProposingAndOpenVoting() public onlyAdmin {
        require(tenderState == TenderState.PROPOSING, "Tender not currently proposing");

        tenderState = TenderState.PROPOSAL_VOTING;
    }

    function closeProposalVotingAndAward() public onlyAdmin {
        require(tenderState == TenderState.PROPOSAL_VOTING, "Tender not currently in proposal voting");

        _awardProposal();

        tenderState = TenderState.AWARDED;
    }

    function updateAdmin(address _newAdmin) public onlyAdmin {
        tenderAdmin = _newAdmin;
    }

    /**
    ----------------------------------------------------- INTERNAL FUNCTIONS ----------------------------------------------------------
     */

    function _awardProposal() internal {
        Project newProject = new Project();

        winningProposal = currentWinningProposal;

        winningProposalContract = address(newProject);
    }

    /**
    --------------------------------------------------------- MODIFIERS ---------------------------------------------------------------
     */

    modifier onlyAdmin() {
        require(msg.sender == tenderAdmin, "Not admin");
        _;
    }

}