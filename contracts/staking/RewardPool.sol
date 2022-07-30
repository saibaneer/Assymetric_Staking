// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardPool is ERC20 {
    constructor(uint initialSupply) ERC20("Rewards", "RWD") {
        _mint(msg.sender, initialSupply);
    }
}