//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;


import "./Creator.sol";

error ImageLicense__AlreadyHasLicense();
error ImageLicense__ListingDoesNotExist();
error ImageLicense__HasNoExtendedLicense();
error ImageLicense__HasNoStandardLicense();
error ImageLicense__NotTheOwner();
error ImageLicense__CannotCallThisFunction();
error ImageLicense__RegisterAsACreatorFirst();


/// @title A contract for creating new license items.
/// @author Toba Ajiboye
/// @notice Only creator's from the creator contract can add new items.
/// @dev All function calls are currently implemented without side effects
contract ImageLicense {   

    //add events
    event NewStandardLicense(address indexed listedBy, uint listingId, uint standardPrice, uint extendedPrice, bool imageAvailability);
    event NewExtendedLicense(address indexed listedBy, uint listingId, uint standardPrice, uint extendedPrice, bool imageAvailability);
    event NewFullLicense(address indexed listedBy, uint listingId, uint standardPrice, uint extendedPrice, bool imageAvailability);
    event AddExtendedLicense(address indexed listedBy, uint listedId, bool extendedLicenseStatus);
    event AddStandardLicense(address indexed listedBy, uint listedId, bool standardLicenseStatus);
    event UpdateStandardLicenseFee(address indexed listedBy, uint listingId, uint oldPrice, uint newPrice);
    event UpdateExtendedLicenseFee(address indexed listedBy, uint listingId, uint oldPrice, uint newPrice);
    event RemoveStandardLicense(address indexed listedBy, uint listingId, bool standardLicense);
    event RemoveExtendedLicense(address indexed listedBy, uint listingId, bool extendedLicense);
    event RemoveLicenseAvailability(address indexed listedBy, uint listingId, bool availability);
    event AddLicenseAvailability(address indexed listedBy, uint listingId, bool availability);



    struct Image {
        address listedBy;
        uint listingId;
        uint standardPrice;
        uint extendedPrice;
        bool standard;
        bool extended;
        bool available;
    }

    Creators creators;
    uint public listingCounter; 
    mapping(address => mapping(uint => Image)) public userToIdToImage; 
    // mapping(address => mapping(uint => uint)) public userToIdToBalance;  

    /// @param _creatorContract is the address of the creator contract.
    constructor(address _creatorContract){
        creators = Creators(_creatorContract);
    }

    /// @dev This function allows a creator to create a standard License
    /// @param _standardPrice is the price the user seeks to set for a license
    function createStandardLicenseOnly(uint _standardPrice) external {
        if(!creators.isCreator(msg.sender)){
            revert ImageLicense__RegisterAsACreatorFirst();
        }
        listingCounter += 1;  
        uint nonce = listingCounter;
        Image memory myLicense = userToIdToImage[msg.sender][nonce];
        myLicense.available = true;
        myLicense.extended = false;
        myLicense.standard = true;
        myLicense.extendedPrice = 0;
        myLicense.standardPrice = _standardPrice;
        myLicense.listingId = nonce;
        myLicense.listedBy = payable(msg.sender);  
        userToIdToImage[msg.sender][nonce] = myLicense;     
         

        emit NewStandardLicense(myLicense.listedBy, nonce, myLicense.standardPrice, myLicense.extendedPrice, myLicense.available);   
    }

    /// @dev The function allows the user to create a full license.
    /// @param _standardPrice @param _extendedPrice are the prices for Both licenses.
    function createBothLicenses(uint _standardPrice, uint _extendedPrice) external {
        if(!creators.isCreator(msg.sender)){
            revert ImageLicense__RegisterAsACreatorFirst();
        }
        listingCounter += 1; 
        uint nonce = listingCounter;
        Image memory myLicense = userToIdToImage[msg.sender][nonce];
        myLicense.available = true;
        myLicense.extended = true;
        myLicense.standard = true;
        myLicense.extendedPrice = _extendedPrice;
        myLicense.standardPrice = _standardPrice;
        myLicense.listingId = nonce;
        myLicense.listedBy = payable(msg.sender);   
        userToIdToImage[msg.sender][nonce] = myLicense; 

        emit NewFullLicense(myLicense.listedBy, nonce, myLicense.standardPrice, myLicense.extendedPrice, myLicense.available);
    }

    /// @dev The function allows a user to add an extended license to a standard license.
    /// @param listingId is the license item being updated, @param _extendedPrice is the associated price.
    function addExtendedLicense(uint listingId, uint _extendedPrice) external {
        Image storage myLicense = userToIdToImage[msg.sender][listingId];
        if(myLicense.extended == true){ revert ImageLicense__AlreadyHasLicense();}
        if(myLicense.available == false){ revert ImageLicense__ListingDoesNotExist();}
        if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        myLicense.extended = true;
        myLicense.extendedPrice = _extendedPrice;
        emit AddExtendedLicense(myLicense.listedBy, myLicense.listingId, myLicense.extended);
    }

    /// @dev the function allows a user to update an existing price for a standard license
    /// @param listingId is the ID for the item to be updated
    /// @param _standardPrice is the price for the standard license.
    function updateStandardLicensePrice(uint listingId, uint _standardPrice) external {
        Image storage myLicense = userToIdToImage[msg.sender][listingId];
        // if(myLicense.standard == true){ revert ImageLicense__AlreadyHasLicense();}
        if(myLicense.available == false){ revert ImageLicense__ListingDoesNotExist();}
        if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        myLicense.standard = true;
        uint previousPrice = myLicense.standardPrice;
        myLicense.standardPrice = _standardPrice;
        emit UpdateStandardLicenseFee(myLicense.listedBy, myLicense.listingId, previousPrice, myLicense.standardPrice);
    }
    
    /// @dev the function allows a user to update an existing price for an extended license
    /// @param listingId is the ID for the item to be updated
    /// @param _extendedPrice is the price for the standard license.
    function updateExtendedLicensePrice(uint listingId, uint _extendedPrice) external {
        Image storage myLicense = userToIdToImage[msg.sender][listingId];
        // if(myLicense.standard == true){ revert ImageLicense__AlreadyHasLicense();}
        if(myLicense.available == false){ revert ImageLicense__ListingDoesNotExist();}
        if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        
        myLicense.extended = true;
        uint previousPrice = myLicense.extendedPrice;
        myLicense.extendedPrice = _extendedPrice;
        emit UpdateExtendedLicenseFee(myLicense.listedBy, myLicense.listingId, previousPrice, myLicense.extendedPrice);
    }

    /// @dev the function allows a user to make an existing license unavailable.
    /// @param listingId is the ID for the item to be updated
    function makeImageUnavailable(uint listingId) external {
        Image storage myLicense = userToIdToImage[msg.sender][listingId];
        if(myLicense.available == false){ revert ImageLicense__ListingDoesNotExist();}
        if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        myLicense.available = false;

        emit RemoveLicenseAvailability(myLicense.listedBy, myLicense.listingId, myLicense.available);
    }

    /// @dev the function allows a user to make an existing license available.
    /// @param listingId is the ID for the item to be updated
    function makeImageAvailable(uint listingId) external {
        Image storage myLicense = userToIdToImage[msg.sender][listingId];        
        if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        if(myLicense.available == true){ revert ImageLicense__CannotCallThisFunction();}
        myLicense.available = true;

        emit AddLicenseAvailability(myLicense.listedBy, myLicense.listingId, myLicense.available);
    }

    /// @dev the function allows a user to view a license object.
    /// @param listingId is the ID for the item object we wish to retrieve 
    function viewImageLicense(uint listingId) public view returns(Image memory) {
        Image memory myLicense = userToIdToImage[msg.sender][listingId];
        if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        return myLicense;
    }

    /// @dev the function allows a user to view the standard price for a license object.
    /// @param listingId is the ID for the item object we wish to retrieve 
    /// @param creator is the address of the creator's ID associated with that license.
    function getStandardLicensePrice(uint listingId, address creator) public view returns(uint) {
        Image memory myLicense = userToIdToImage[creator][listingId];
        // if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        return myLicense.standardPrice;
    }

    /// @dev the function allows a user to view the extended price for a license object.
    /// @param listingId is the ID for the item object we wish to retrieve 
    /// @param creator is the address of the creator's ID associated with that license.
    function getExtendedLicensePrice(uint listingId, address creator) public view returns(uint) {
        Image memory myLicense = userToIdToImage[creator][listingId];
        // if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        return myLicense.extendedPrice;
    }

    /// @dev the function allows a user to view the creator address for a license object.
    /// @param listingId is the ID for the item object we wish to retrieve 
    /// @param creator is the address of the creator's ID associated with that license.
    function getCreatorAddress(uint listingId, address creator) public view returns(address) {
        Image memory myLicense = userToIdToImage[creator][listingId];
        // if(myLicense.listedBy != msg.sender){ revert ImageLicense__NotTheOwner();}
        return myLicense.listedBy;
    }

    /// @dev the function allows a user to view whether a license for an object exists.
    /// @param listingId is the ID for the item object we wish to retrieve 
    /// @param creator is the address of the creator's ID associated with that license.
    function licenseExists(uint listingId, address creator) public view returns(bool) {
        Image memory myLicense = userToIdToImage[creator][listingId];
        if(myLicense.available == false && myLicense.listingId != 0){
            return false;
        } else if(myLicense.available == false && myLicense.listingId == 0) {
            return false;
        } else {
            return true;
        }
    }

    
    
}