// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "./RewardPool.sol";
import "./StakingToken.sol";
import "../main/Creator.sol";

error Staking__NotACreator();
error Staking__StakingPeriodIsClosed();

/// @title A contract for staking Monion tokens. This contract only permits staking for 120 days.
/// @author Toba Ajiboye
/// @notice Only creator's from the creator contract can add new items.
/// @dev All function calls are currently implemented without side effects
contract AssymetricStaking {

    event Staked(address creator, uint amount);
    event Unstaked(address creator, uint amount);
    event WithdrawAllMonion(address creator);
    event ClaimedRewards(address creator, uint rewards);

    RewardPool rewardTokens;
    StakingToken stakingTokens;
    Creators newCreator;
    

    mapping(address => uint) public stakerToDepositTime;
    mapping(address => uint) public stakerRewards;

    mapping(address => bool) public claimed;
    mapping(address => uint) public stakerBalance;
    mapping(address => bool) public inserted;
    address[] public addresses;

    uint public totalStakedBalance;
    uint public rewardPoolTotal;
    uint public rewardPoolBalance;
    
    uint public totalRewardConstant_Owner;
    uint public constant contractLifetime = 60*60*24*120;

    uint public contractTermination;
    address public owner;

    modifier updateReward(address account) {
        calcReward(account);
        _;
    }

    /// @notice The constructor sets the key state variables. 
    /// @param _rewardsToken is the contract address for the rewards token
    /// @param _stakingToken is the contract address for the staking token
    /// @param _creatorContract is the contract address for the creator's contract.
    constructor(address _rewardsToken, address _stakingToken, address _creatorContract){
        owner = msg.sender;
        contractTermination = block.timestamp + contractLifetime;
        rewardTokens = RewardPool( _rewardsToken);
        stakingTokens = StakingToken(_stakingToken);
        newCreator = Creators(_creatorContract);
        rewardPoolTotal = 100000;
        rewardPoolBalance = rewardPoolTotal;
        
    }

    /// @notice This function allows a user stake their Monion tokens. 
    /// @param amount is the amount a user seeks to stake.
    function stake(uint amount) public updateReward(msg.sender) {
        if(!newCreator.isCreator(msg.sender)){
            revert Staking__NotACreator();
        }
        if(block.timestamp > contractTermination){
            revert Staking__StakingPeriodIsClosed();
        }
        
        stakingTokens.approve(address(this), amount);
        stakingTokens.transferFrom(msg.sender, address(this), amount);
        stakerBalance[msg.sender] += amount;
        totalStakedBalance += amount;
        if(!inserted[msg.sender]){
            inserted[msg.sender] == true;
            addresses.push(msg.sender); //emit index.
        }
        stakerToDepositTime[msg.sender] = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    /**
     */
    function calcReward(address account) internal {
        if(stakerBalance[account] == 0) {
            stakerRewards[account] = 0;
        } else {
            uint diff = block.timestamp - stakerToDepositTime[account];
            if(block.timestamp > contractTermination){
            revert Staking__StakingPeriodIsClosed();
            }
            stakerRewards[account] += ((contractTermination - diff)*stakerBalance[account])/contractLifetime;
            stakerToDepositTime[account] = block.timestamp;
            
        }
        
    }

    /// @notice This function allows a user to unstake their Monion tokens. 
    /// @param amount is the amount a user seeks to unstake.
    function unstake(uint amount) external {
        require(stakerBalance[msg.sender] - amount >= 0, "You cannot unstake this amount");
        stakerBalance[msg.sender] -= amount; //prevent overflow
        totalStakedBalance -= amount;
        
        stakerRewards[msg.sender] = 0;

        stakingTokens.transfer(msg.sender, amount);
        emit Unstaked(msg.sender, amount);
    }

    /// @notice This function allows a user withdraw their Monion tokens after the period has expired. 
    function withdrawMonion() external {
        require(block.timestamp > contractTermination, "You cannot call this function until expiration!");
        uint amount = stakerBalance[msg.sender];
        stakerBalance[msg.sender] = 0;
        stakingTokens.transfer(msg.sender, amount);
        emit WithdrawAllMonion(msg.sender);
    }

    /**
     */
    function getSize() external view returns(uint) {
        return addresses.length;
    }

    /// @notice This function allows the admin to compute the total rewards factor. 
    function computeTotalRewardsConstant() external {
        require(msg.sender == owner, "You are not authorized.");
        require(block.timestamp > contractTermination, "You cannot call this contract yet!");
        //VERY EXPENSIVE OPERATION
        
        for(uint i=0; i < addresses.length; i++){
            
            uint timeDiff = contractTermination - stakerToDepositTime[addresses[i]];
            uint timeFactor = (timeDiff*stakerBalance[addresses[i]])/contractLifetime;
            totalRewardConstant_Owner += stakerRewards[addresses[i]] + timeFactor;
        }

    }

    /// @notice This function allows a user claim  their rewards in a stable token. 
    function claimRewards() external {
        require(block.timestamp > contractTermination, "You cannot call this contract until termination!");
        require(!claimed[msg.sender], "You have already claimed rewards!");
        require(totalRewardConstant_Owner != 0, "You cannot call this contract yet!");
        uint timeDiff = contractTermination - stakerToDepositTime[msg.sender];
        uint timeFactor = (timeDiff*stakerBalance[msg.sender])/contractLifetime;
        stakerRewards[msg.sender] += timeFactor;
        uint bps = (10000 * stakerRewards[msg.sender])/totalRewardConstant_Owner;
        uint payout = (bps*rewardPoolTotal)/10000;

        rewardPoolBalance -= payout;
        claimed[msg.sender] = true;
        // rewardTokens.approve(msg.sender, payout);
        rewardTokens.transfer(msg.sender, payout);
        
        

        emit ClaimedRewards(msg.sender, payout);

    }


}