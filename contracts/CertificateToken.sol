// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


contract CertificateToken is Context, AccessControl, ERC20 {
    uint8 internal _decimals = 18;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    event Minted(address indexed to, uint256 amount);
    event Burned(address indexed from, uint256 amount);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, address staking) ERC20(name_, symbol_) {
        _decimals = decimals_;
        // Grant default admin role to the deployer
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        // Grant minter and burner roles to the staking contract
        grantRole(MINTER_ROLE, staking);
        grantRole(BURNER_ROLE, staking);
        // Revoke the deployer's admin role to enhance security
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function decimals() public override view virtual returns (uint8) {
        return _decimals;
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
        emit Minted(to, amount);
    }

    function burnFrom(address from, uint256 value) public onlyRole(BURNER_ROLE) {
        _burn(from, value);
        emit Burned(from, value);
    }
}
