// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

//@title GrantVault
//@notice This contract holds ETH safely for release to project owners upon the approval of proposals

contract GrantVault is ReentrancyGuard {
//==========state===========
    address public manager;
    uint public totalFunds;

///===============events====================

    event VaultFunded(address indexed funder, uint amount);
    event GrantReleased(uint indexed projectId, address indexed recipient, uint amount);

//==================custom errors===========

    error NotManager();
    error InsufficientBalance();
    error TransferFailed();
    error DepositMustBeGreaterThanZero();

//===========constructor=====================

    constructor(address _manager) {
        manager = _manager; // deployer is the default manager
    }
//==========modifier=======================
// @ notice pre check

    modifier onlyManager() {
        if (msg.sender != manager) revert NotManager();
        _;
    }
///==========core logic=================
//  @notice  deposit ETH by calling this function or the receive().

    function fundVault() external payable {
        if (msg.value == 0) revert DepositMustBeGreaterThanZero(); // caller must deposit some ETH
        totalFunds += msg.value;
        unchecked{totalFunds+=msg.value;} // ensures no overflows

        emit VaultFunded(msg.sender, msg.value);
    }

// @notice once a project has been approved and its proposal executed, the IncubatorManager.sol contract calls this func
//@ notice the use of the CEI pattern to protect against reentrancy attacks, esp when making low level calls
//@ notice using ReentrancyGuard without upholding the CEI (checks, effects, and interactions) pattern is tatamount to not applying it.

    function releaseGrant(uint projectId, address payable recipient, uint amount)
        external
        nonReentrant
        onlyManager
    {
        if (address(this).balance < amount) revert InsufficientBalance(); // checks.....ensures funds requested do not exceed the contract's balance. 
        totalFunds -= amount;  // effects.....updattes states before making an low level/external call

        (bool success, ) = recipient.call{value: amount}("");     // low level call for ETH transfers called by the recipient 
        if (!success) revert TransferFailed();         // this bubbles up an error in case of failure, otherwise the fail will be silent.

        emit GrantReleased(projectId, recipient, amount);
    }
// @notice this function receives plain ETH transfers and emits an event to that effect.
//@notice upon receipt of funds: state is updated and an event is emited 

    receive() external payable {
        totalFunds += msg.value;
        emit VaultFunded(msg.sender, msg.value);
    }
//=========helper functions===================
//@ notice this helps check the contracts balance quick and avoids repeated reads to the storage

    function vaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function setManager(address newManager) external {
        if (msg.sender != manager) revert NotManager();
        manager = newManager;
    }
}
