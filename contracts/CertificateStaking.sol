// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./CertificateToken.sol";

contract CertificateStaking is Ownable {

    struct RoundHistory {
        uint256 amount;
        uint256 limit;
        uint256 startTime;
        uint256 endTime;
    }

    address public stakedToken;
    address public certificateToken;

    uint256 public round;
    mapping(uint256 => RoundHistory) public withdrawRounds;
    uint256 public withdrawAmount;
    uint256 public withdrawLimit;
    uint256 public withdrawStartTime;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    event WithdrawConfig(uint256 limit, uint256 startTime);

    constructor(address _stakedToken, string memory _certificateName, string memory _certificateSymbol) Ownable(_msgSender()) {
        stakedToken = _stakedToken;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _certificateName, _certificateSymbol));
        certificateToken = address(new CertificateToken{salt: salt}(_certificateName, _certificateSymbol, address(this)));
        round = 0;
        withdrawLimit = 0;
        withdrawAmount = 0;
        withdrawStartTime = block.timestamp + 86400 * 60;
    }

    function deposit(uint256 _amount) external {
        require(ERC20(stakedToken).allowance(_msgSender(), address(this)) >= _amount, "CertificateStaking: deposit: Insufficient allowance");
        ERC20(stakedToken).transferFrom(_msgSender(), address(this), _amount);
        CertificateToken(certificateToken).mint(_msgSender(), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) external {
        require(CertificateToken(certificateToken).balanceOf(_msgSender()) >= _amount, "CertificateStaking: withdraw: Insufficient balance");
        require(ERC20(stakedToken).balanceOf(address(this)) >= _amount, "CertificateStaking: withdraw: No enough staked token");
        require(block.timestamp >= withdrawStartTime, "CertificateStaking: withdraw: Withdraw has not started yet");
        require(_amount + withdrawAmount <= withdrawLimit, "CertificateStaking: withdraw: Withdraw limit exceeded");
        CertificateToken(certificateToken).burnFrom(_msgSender(), _amount);
        ERC20(stakedToken).transfer(_msgSender(), _amount);
        withdrawAmount = withdrawAmount + _amount;
        emit Withdraw(_msgSender(), _amount);
    }

    function setWithdrawConfig(uint256 _limit, uint256 _startTime) external onlyOwner {
        withdrawRounds[round] = RoundHistory(withdrawAmount, withdrawLimit, withdrawStartTime, block.timestamp);
        round = round + 1;
        withdrawLimit = _limit;
        withdrawStartTime = _startTime;
        withdrawAmount = 0;
        emit WithdrawConfig(_limit, _startTime);
    }
}
