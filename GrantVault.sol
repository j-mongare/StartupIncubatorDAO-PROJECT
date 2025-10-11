// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//@title GrantVault
//@notice This contract holds ETH safely for release to project owners upon the approval of proposals

contract GrantVault is ReentrancyGuard {
    address public manager;
    uint public totalFunds;

    event VaultFunded(address indexed funder, uint amount);
    event GrantReleased(uint indexed projectId, address indexed recipient, uint amount);

    error NotManager();
    error InsufficientBalance();
    error TransferFailed();
    error DepositMustBeGreaterThanZero();

    constructor(address _manager) {
        manager = _manager;
    }

    modifier onlyManager() {
        if (msg.sender != manager) revert NotManager();
        _;
    }

    function fundVault() external payable {
        if (msg.value == 0) revert DepositMustBeGreaterThanZero();
        totalFunds += msg.value;
        emit VaultFunded(msg.sender, msg.value);
    }

    function releaseGrant(uint projectId, address payable recipient, uint amount)
        external
        nonReentrant
        onlyManager
    {
        if (address(this).balance < amount) revert InsufficientBalance();
        totalFunds -= amount;

        (bool success, ) = recipient.call{value: amount}("");
        if (!success) revert TransferFailed();

        emit GrantReleased(projectId, recipient, amount);
    }

    receive() external payable {
        totalFunds += msg.value;
        emit VaultFunded(msg.sender, msg.value);
    }

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setManager(address newManager) external {
        if (msg.sender != manager) revert NotManager();
        manager = newManager;
    }
}
