// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// @title Project Registry
// @notice Keeps records of startup projects registered in the incubator system

contract ProjectRegistry {
    struct Project {
        uint id;
        address owner;
        string name;
        string description;
        bool approved;
    }

    uint public nextProjectId;
    mapping(uint => Project) public projects;
    address public manager;

    event ProjectRegistered(uint indexed id, address owner, string name);
    event ProjectApproved(uint indexed id, address indexed approver);

    error NotManager();
    error InvalidProject();

    constructor(address _manager) {
        manager = _manager;
    }

    function registerProject(string calldata name, string calldata description) external {
        uint id = nextProjectId;
        unchecked { nextProjectId = id + 1; }

        projects[id] = Project({
            id: id,
            owner: msg.sender,
            name: name,
            description: description,
            approved: false
        });

        emit ProjectRegistered(id, msg.sender, name);
    }

    function approveProject(uint id) external {
        if (msg.sender != manager) revert NotManager();

        Project storage p = projects[id];
        if (p.owner == address(0)) revert InvalidProject();

        if (!projects[id].approved) {
            projects[id].approved = true;
        }

        emit ProjectApproved(id, msg.sender);
    }

    function getProject(uint id) external view returns (Project memory) {
        return (projects[id]);
    }

    function setManager(address newManager) external {
        if (msg.sender != manager) revert NotManager();
        manager = newManager;
    }
}
