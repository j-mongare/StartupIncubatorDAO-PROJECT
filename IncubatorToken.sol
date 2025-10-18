// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// @notice Reputation token for contribution rewards and DAO voting
// @title Incubation Reputation Token (IREP)

contract IncubatorToken is ERC20, AccessControl {
// @notice hashing the MINTER_ROLE to ensure subsequent minters each have unique identifiers
 bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE"); 

event _Transfer(address indexed _from, address indexed to, uint256 amount);

    constructor() ERC20("Incubator Reputation Token", "IREP") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // deployer is the default admin
    }

    function mint(address to, uint amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
      address _from = address(0);
      emit _Transfer(_from, to, amount);
    }
}
