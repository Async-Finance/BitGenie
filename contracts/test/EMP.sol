// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EMP is ERC20 {
    constructor(uint256 initialSupply) ERC20("Emporium Token", "EMP") {
        _mint(msg.sender, initialSupply * 10 ** 18);
    }
}