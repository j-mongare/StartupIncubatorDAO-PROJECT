// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./IncubatorToken.sol";
import "./ProjectRegistry.sol";
import "./GrantVault.sol";

/// @title IncubatorManager
/// @notice Coordinates projects, proposals, voting, rewards, and ETH grant distribution.
contract IncubatorManager {
    struct Proposal {
        uint256 id;
        uint256 projectId;
        address proposer;
        uint256 amount;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 deadline;
        bool executed;
    }
//==========state============

    IncubatorToken public immutable IREP;
    GrantVault public immutable vault;
    ProjectRegistry public immutable registry;

    uint256 public constant MIN_IREP_TO_PROPOSE = 10 * 1e18;
    uint256 public constant MIN_IREP_TO_VOTE = 20 * 1e18;
    uint256 public constant VOTING_DURATION = 5760; // ~1 day in blocks

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId;

//============events============

    event ProposalCreated(uint256 indexed id, uint256 indexed projectId, address proposer);
    event Voted(uint256 indexed id, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id, bool passed);

//===============custom errors====================

    error InsufficientIREP();
    error AlreadyVoted();
    error ProposalNotFound();
    error VotingClosed();
    error AlreadyExecuted();
    error NotApprovedProject();

//================constructor==================================

    constructor(address _IREP, address payable _vault, address _registry) {
        IREP = IncubatorToken(_IREP);
        vault = GrantVault(_vault);
        registry = ProjectRegistry(_registry);
    }
//=================core functions============
// @ notice create a funding proposal for an approved project

    function createProposal(uint256 projectId, uint256 amount) external {
        if (IREP.balanceOf(msg.sender) < MIN_IREP_TO_PROPOSE) revert InsufficientIREP();
        if (!registry.getProject(projectId).approved) revert NotApprovedProject();

        uint256 id = nextProposalId;
        unchecked { nextProposalId = id + 1; }

        proposals[id] = Proposal({
            id: id,
            projectId: projectId,
            proposer: msg.sender,
            amount: amount,
            forVotes: 0,
            againstVotes: 0,
            deadline: block.number + VOTING_DURATION,
            executed: false
        });

        emit ProposalCreated(id, projectId, msg.sender);
    }

//@ notice vote on a proposal 

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        if (p.id != proposalId) revert ProposalNotFound();
        if (block.number > p.deadline) revert VotingClosed();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

// @ notice check whether caller has the minimum required IREP TO PROCEED WITH ACTION

        uint256 weight = IREP.balanceOf(msg.sender);
        if (weight < MIN_IREP_TO_VOTE) revert InsufficientIREP();

//@ notice record that caller has voted
     hasVoted[proposalId][msg.sender] = true;

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }
// @notice emit an event to frontends. This also ensures transparency in the process.
        emit Voted(proposalId, msg.sender, support, weight);
    }

/// @ notice execute a proposal after voting ends

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        if (p.executed) revert AlreadyExecuted();
        if (block.number <= p.deadline) revert VotingClosed();

        bool passed = p.forVotes > p.againstVotes;
        p.executed = true;

        if (passed) {
// @notice retrieve the Id of the project whose proposal has passed and has been executed 
            ProjectRegistry.Project memory project = registry.getProject(p.projectId);

//@notice call vault to release funds to the project
            vault.releaseGrant(p.projectId, payable(project.owner), p.amount);
        }

        emit ProposalExecuted(proposalId, passed);
    }
// ============Adminstrative/incentives========
// @ notice reward users for participation

    function rewardActiveVoter(address voter, uint256 amount) external {
        if (voter == address(0)) revert("Invalid address");
        if (amount == 0) revert("Invalid amount");

// @notice call IREP mint() to mint IREP 
        IREP.mint(voter, amount);
    }
}
