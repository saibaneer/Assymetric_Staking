//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title A contract for adding fees to the license sale.
/// @author Toba Ajiboye
/// @notice Admin SHOULD set fees in order to implement fees in Commerce contract contract.
/// @dev All function calls are currently implemented without side effects
contract Fees {

    address public immutable admin;
    uint public marketFee;
    uint public minimumDeposit;
    
    constructor(){
        admin = msg.sender;
    }

    /// @notice This function allows the admin to set a fee that would be charged per license sold.
    function setFee(uint amount) external {
        require(admin == msg.sender, "You are not authorized!");
        marketFee = amount;
    }

    /// @notice This function allows the admin to get a fee that has been set.
    function getFee() external view returns(uint) {
        // require(admin == msg.sender, "You are not authorized!");
        return marketFee;
    }
    
    // function setMinimumDeposit(uint amount) external {
    //     require(admin == msg.sender, "You are not authorized!");
    //     minimumDeposit = amount;
    // }


}