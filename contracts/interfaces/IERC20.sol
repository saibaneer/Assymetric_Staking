// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
interface IERC20 {

    // function deposit() external payable;
    // function withdraw(uint256 amount) external;
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}