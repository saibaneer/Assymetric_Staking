//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./ImageLicense.sol";
import "./Fees.sol";
import "./Creator.sol";

error Commerce__InsufficientDeposit (uint256 sent, uint256 minRequired);
error Commerce__UnAuthorizedWithdrawal();

/// @title A contract for purchasing licenses from ImageLicense.sols
/// @author Toba Ajiboye
/// @notice This contract has dependencies as indicated  by the import statments.
/// @dev All function calls are currently implemented without side effects

contract Commerce {

    event WithdrewFundsForSeller(address creator, uint listingId, uint amount);
    event BoughtFullLicense(address creator, uint listingId, uint amount, address buyer);
    event BoughtStandardLicense(address creator, uint listingId, uint amount, address buyer);

    address payable immutable owner;
    mapping(address => mapping(uint => uint)) public creatorToIdToDeposit;
    mapping(address => uint) public ownerHT;
    ImageLicense license;
    Fees fees;
    Creators creators;
    
    
    /// @notice The constructor takes in 3 parameters. These parameters are namely the Image License, the Admin contract, the creator contract
    constructor(address _licenseContractAddress, address _fees, address _creators){
        owner = payable(msg.sender);
        license = ImageLicense(_licenseContractAddress);
        fees = Fees(_fees);
        creators = Creators(_creators);
    }


 
    /// @notice The function allows a user to purchase a Standard license. The buyer must provide the listingId and the creator's address.
    function buyStandardLicense(uint listingId, address creator) payable external {
        uint price = license.getStandardLicensePrice(listingId, creator);
        if(msg.value < price){
            revert Commerce__InsufficientDeposit({sent: msg.value, minRequired: price});
        }
        uint amount = msg.value;
        uint feePercent = fees.getFee();
        uint dueMarketplace = amount * feePercent/10000;
        uint dueSeller = amount - dueMarketplace;

        creatorToIdToDeposit[creator][listingId] += dueSeller;
        creators.addToBalance(creator, dueSeller);
        ownerHT[owner] += dueMarketplace;
        dueSeller = 0;

        emit BoughtStandardLicense(creator, listingId, amount, msg.sender);

    }

   
    /// @notice The function allows a user to purchase an Extended license. The buyer must provide the listingId and the creator's address.
    function buyExtendedLicense(uint listingId, address creator) payable external {
        uint price = license.getExtendedLicensePrice(listingId, creator);
        if(msg.value < price){
            revert Commerce__InsufficientDeposit({sent: msg.value, minRequired: price});
        }
        uint amount = msg.value;
        uint feePercent = fees.getFee();
        uint dueMarketplace = amount * feePercent/10000;
        uint dueSeller = amount - dueMarketplace;

        creatorToIdToDeposit[creator][listingId] += dueSeller;
        creators.addToBalance(creator, dueSeller);
        ownerHT[owner] += dueMarketplace;
        dueSeller = 0;

        emit BoughtFullLicense(creator, listingId, amount, msg.sender);
    }

 
    /// @notice The function allows a user to withdraw funds. The buyer must provide the listingId.
    function withdrawFundsForSeller(uint listingId) external {
        address creator = license.getCreatorAddress(listingId, msg.sender);
        if(msg.sender != creator){
            revert Commerce__UnAuthorizedWithdrawal();
        }
        uint amount = creatorToIdToDeposit[msg.sender][listingId];
        require(amount > 0, "Insufficient funds!");
        (bool success, ) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to send Ether");
        creators.subtractFromBalance(msg.sender, amount);        

        emit WithdrewFundsForSeller(msg.sender, listingId, amount);
    }

    
    /// @dev The function allows a user to withdraw funds a Standard license.
    function withdrawFundsForOwner() external {
        if(msg.sender != owner){
            revert Commerce__UnAuthorizedWithdrawal();
        }
        uint amount = ownerHT[owner];
        (bool success, ) = payable(msg.sender).call{ value: amount }("");
        require(success, "Failed to send Ether");
        ownerHT[owner] = 0;
    }

    
}