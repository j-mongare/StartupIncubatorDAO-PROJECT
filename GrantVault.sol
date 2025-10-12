// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


//@ title GrantVault
//@notice this contract holds ETH safely for release to project owners upon the approval of proposals

contract GrantVault is ReentrancyGuard, Pausable{
    //======state vars========
    address public manager;
    address public admin;
    uint public totalFunds;

    //========events for transparency===========
    event VaultInitialized(address  manager, address admin);
    event VaultFunded(address indexed funder, uint amount);
    event GrantReleased(uint indexed projectId, address indexed recepient, uint amount);
    event EmergencyETHWithdrawn(address to, uint256 amount, uint256 timestamp);
    event ERC20Recovered(address token, address to, uint256 amount);
    event VaultPaused(address admin);
    event VaultUnpaused(address admin);
    event ManagerChanged(address indexed oldManager, address indexed newManager);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    ///============custom errors=======
    error NotManager();
    error NotAdmin();
    error InsufficientBalance();
    error TransferFailed();
    error DepositMustBeGreaterThanZero();

    constructor(address _manager, address _admin){ 
        manager= _manager;
        admin = _admin;

        emit VaultInitialized(_manager, _admin);
        
        }

    // ========modifier(prechecks/wrapper to govern contract behavior like restricting key functions)=========
     // used for functions that withdraw or release funds to projects
    modifier onlyManager(){
       
        if(msg.sender!= manager)revert NotManager();
        _;
       

    }
    //@notice admin is a high level recovery key only used during emergencies
    modifier onlyAdmin(){
        if(msg.sender != admin) revert NotAdmin();
        _;
    }
    //======core functions==========
    // @notice anyone can call this function and deposit ETH therein
    function fundVault()external payable whenNotPaused {
        if(msg.value == 0)revert DepositMustBeGreaterThanZero();

       unchecked { totalFunds += msg.value; }

      

        emit VaultFunded(msg.sender, msg.value);

    }
    // @notice the manager triggers this to pay an approved project

    function releaseGrant(uint projectId, address payable recipient, uint amount)external nonReentrant whenNotPaused onlyManager{
        if(address(this).balance < amount) revert InsufficientBalance();
        totalFunds -= amount;

       (bool success, ) = recipient.call{value: amount}("");
       if(!success) revert TransferFailed();


       emit GrantReleased(projectId, recipient, amount );

    }
    //@notice this provides a recovery path in the event the manager contract breaks
    // or DAO decides to migrate funds

    function emergencyWithdrawETH(address payable to, uint256 amount)external onlyAdmin{
      if(amount > address(this).balance) revert InsufficientBalance();
     
      unchecked{totalFunds-= amount;}

      (bool success,)= to.call{value: amount}("");
      if(!success)revert TransferFailed();

      emit EmergencyETHWithdrawn(to, amount, block.timestamp);
    }
    //@notice this ensures that users who accidentally send tokens to the vault are able to recover them.

    function recoverERC20(address token, uint256 amount, address to)onlyAdmin external{
    uint256 balance = IERC20(token).balanceOf(address(this));
     if (amount > balance)revert InsufficientBalance();

       IERC20(token).transfer(to, amount);

       emit ERC20Recovered(token,  to, amount);
    }
    // @notice if something goes wrong, the admin can pause the vault
    // while retaining the ability to withdraw emergency funds.
    
function _pauseVault() internal whenNotPaused onlyAdmin {
        _pause();

        emit VaultPaused(msg.sender);
    }
    function unpauseVault()internal whenPaused onlyAdmin{
       _unpause();

        emit VaultUnpaused(msg.sender);

    }
 
    
    // @ notice receive() for direct ETH transfers

    receive() external payable{
        unchecked{totalFunds += msg.value;}
        emit VaultFunded(msg.sender, msg.value);
    }
// @notice call this function to check the contract's balance

    function vaultBalance()external view returns(uint256){
        return address(this).balance;

    }
    function setManager(address newManager) external onlyManager{
        if(newManager == address(0)) revert NotManager();
        manager= newManager;

        emit ManagerChanged(msg.sender, newManager);

    }
    function setAdmin(address newAdmin)external onlyAdmin{
        if(newAdmin == address(0)) revert NotAdmin();
        admin= newAdmin;

        emit AdminChanged(msg.sender, newAdmin);
    }
    

}
