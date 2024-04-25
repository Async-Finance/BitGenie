// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DOGE is ERC20 {
    constructor(uint256 initialSupply) ERC20("DOGE test Token", "DOG") {
        _mint(msg.sender, initialSupply * 10 ** 5);
    }

    function decimals() public view virtual override returns (uint8) {
        return 5;
    }
}