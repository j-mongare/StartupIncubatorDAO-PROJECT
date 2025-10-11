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

    IncubatorToken public immutable IREP;
    GrantVault public immutable vault;
    ProjectRegistry public immutable registry;

    uint256 public constant MIN_IREP_TO_PROPOSE = 10 * 1e18;
    uint256 public constant MIN_IREP_TO_VOTE = 20 * 1e18;
    uint256 public constant VOTING_DURATION = 5760;

    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public hasVoted;
    uint256 public nextProposalId;

    event ProposalCreated(uint256 indexed id, uint256 indexed projectId, address proposer);
    event Voted(uint256 indexed id, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 indexed id, bool passed);

    error InsufficientIREP();
    error AlreadyVoted();
    error ProposalNotFound();
    error VotingClosed();
    error AlreadyExecuted();
    error NotApprovedProject();

    constructor(address _IREP, address payable _vault, address _registry) {
        IREP = IncubatorToken(_IREP);
        vault = GrantVault(_vault);
        registry = ProjectRegistry(_registry);
    }

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

    function vote(uint256 proposalId, bool support) external {
        Proposal storage p = proposals[proposalId];
        if (p.id != proposalId) revert ProposalNotFound();
        if (block.number > p.deadline) revert VotingClosed();
        if (hasVoted[proposalId][msg.sender]) revert AlreadyVoted();

        uint256 weight = IREP.balanceOf(msg.sender);
        if (weight < MIN_IREP_TO_VOTE) revert InsufficientIREP();

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        emit Voted(proposalId, msg.sender, support, weight);
    }

    function executeProposal(uint256 proposalId) external {
        Proposal storage p = proposals[proposalId];
        if (p.executed) revert AlreadyExecuted();
        if (block.number <= p.deadline) revert VotingClosed();

        bool passed = p.forVotes > p.againstVotes;
        p.executed = true;

        if (passed) {
            ProjectRegistry.Project memory project = registry.getProject(p.projectId);
            vault.releaseGrant(p.projectId, payable(project.owner), p.amount);
        }

        emit ProposalExecuted(proposalId, passed);
    }

    function rewardActiveVoter(address voter, uint256 amount) external {
        if (voter == address(0)) revert("Invalid address");
        if (amount == 0) revert("Invalid amount");
        IREP.mint(voter, amount);
    }
}
