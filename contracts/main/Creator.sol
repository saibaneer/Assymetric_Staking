//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/// @title A contract for adding new creators.
/// @author Toba Ajiboye
/// @notice Creator must first be added before they can list in the ImageLicense.sol contract.
/// @dev All function calls are currently implemented without side effects
contract Creators {

    event NewCreator(address creatorAddress, uint creatorId, bool creatorIsWhitelisted);
    event IsVerified(address creatorAddress, bool isVerified);

    /**
     */
    struct Creator {
        address creatorAddress;
        uint creatorId;
        uint256 licenseCount;
        uint256 balance;
        bool isWhitelisted; 
        bool isVerified;       
    }
    
    
    uint public creatorNonce;

    mapping(address => Creator) public addressToCreator;
    mapping(address => uint) public creatorToId;
    mapping(uint => address) public idToCreator;
    mapping(address => bool) public creatorExists;
    mapping(address => uint) public whitelistIndex;


    /**
    * @dev This function allows a user to add a new creator. This function generates a nonce which uniquely identifies each creator.
     */
    function addCreator() external {
        require(creatorExists[msg.sender] == false, "User already exists");
        creatorNonce += 1;
        Creator memory record = addressToCreator[msg.sender];
        record.creatorAddress = msg.sender;
        record.creatorId = creatorNonce;
        record.licenseCount = 0;
        record.balance = 0;
        record.isWhitelisted = false;
        record.isVerified = false;
        addressToCreator[msg.sender] = record;

        //update mappings
        creatorToId[msg.sender] = creatorNonce;
        idToCreator[creatorNonce] = msg.sender;
        creatorExists[msg.sender] = true;

        emit NewCreator(record.creatorAddress, record.creatorId, record.isWhitelisted);
    }

    /**
    *  @notice This function allows the user to view a Creator's object. This function takes in 1 parameter, the creator's address.
    */
    function viewCreatorInfo(address _creator) external view returns(Creator memory) {
        Creator memory record = addressToCreator[_creator];
        return record;
    }

    /// @notice This function allows a user to check if a creator exists. This function takes in 1 parameter, the creator's address.
    function isCreator(address _creator) external view returns(bool) {
        if(!creatorExists[_creator]){
            return false;
        } 

        return true;
    }

    /// @notice This function allows a user to check the creator's balance. This function takes in 1 parameter, the creator's address.
    function creatorBalance(address _creator) external view returns(uint) {
        Creator storage record = addressToCreator[_creator];
        return record.balance;
    }

    /// @notice This function is a helper that allows the contract to add to the creator's balance. This function takes in 2 parameters, the creator's address and the amount.
    function addToBalance(address _creator, uint amount) public {
        Creator storage record = addressToCreator[_creator];
        record.balance += amount;
    }

    /// @notice This function is a helper that allows the contract to reduce from the creator's balance. This function takes in 2 parameters, the creator's address and the amount.
    function subtractFromBalance(address _creator, uint amount) public {
        Creator storage record = addressToCreator[_creator];
        record.balance -= amount;
    }

    /// @notice This function is allows the user to whitelist a creator for special services. This function takes in 1 parameter, the creator's address.
    function whitelistCreator(address _creator) external {
        //require msg!
        Creator storage record = addressToCreator[_creator];
        record.isWhitelisted = true;        
    }

    /// @notice This function is allows the user to whitelist a creator for special services. This function takes in 1 parameter, the creator's address.
    function removeWhitelist(address _creator) external {
        //require msg!
        Creator storage record = addressToCreator[_creator];
        record.isWhitelisted = false;      
    }

    /// @notice This function is allows the user to whitelist a creator for special services. This function takes in 1 parameter, the creator's address.
    function verifyCreator() payable external {
        Creator storage record = addressToCreator[msg.sender];
        //
        record.isVerified = true;
        emit IsVerified(msg.sender, record.isVerified);
    }

    // function viewCreatorBalance() external view returns(uint) {
    //     return
    // }
}