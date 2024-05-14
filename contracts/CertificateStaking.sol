// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./CertificateToken.sol";

contract CertificateStaking is Ownable, ReentrancyGuard {

    using SafeERC20 for ERC20;

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

    event WithdrawConfig(uint256 limit, uint256 startTime, uint256 lastLimit, uint256 lastStartTime);

    constructor(address _stakedToken, string memory _certificateName, string memory _certificateSymbol) Ownable(_msgSender()) {
        stakedToken = _stakedToken;
        bytes32 salt = keccak256(abi.encodePacked(_stakedToken, _certificateName, _certificateSymbol));
        uint8 stakedTokenDecimal = ERC20(_stakedToken).decimals();
        certificateToken = address(new CertificateToken{salt: salt}(_certificateName, _certificateSymbol, stakedTokenDecimal, address(this)));
        round = 0;
        withdrawLimit = 0;
        withdrawAmount = 0;
        withdrawStartTime = block.timestamp + 86400 * 60;
    }

    /**
     * @dev Deposits staked tokens and mints certificate tokens.
     * @param _amount Amount of staked tokens to deposit.
     */
    function deposit(uint256 _amount) external {
        require(ERC20(stakedToken).allowance(_msgSender(), address(this)) >= _amount, "CertificateStaking: deposit: Insufficient allowance");
        ERC20(stakedToken).safeTransferFrom(_msgSender(), address(this), _amount);
        CertificateToken(certificateToken).mint(_msgSender(), _amount);
        emit Deposit(_msgSender(), _amount);
    }

    /**
     * @dev Withdraws staked tokens by burning certificate tokens.
     * @param _amount Amount of staked tokens to withdraw.
     */
    function withdraw(uint256 _amount) external nonReentrant {
        require(CertificateToken(certificateToken).balanceOf(_msgSender()) >= _amount, "CertificateStaking: withdraw: Insufficient balance");
        require(ERC20(stakedToken).balanceOf(address(this)) >= _amount, "CertificateStaking: withdraw: No enough staked token");
        require(block.timestamp >= withdrawStartTime, "CertificateStaking: withdraw: Withdraw has not started yet");
        require(_amount + withdrawAmount <= withdrawLimit, "CertificateStaking: withdraw: Withdraw limit exceeded");
        CertificateToken(certificateToken).burnFrom(_msgSender(), _amount);
        ERC20(stakedToken).safeTransfer(_msgSender(), _amount);
        withdrawAmount = withdrawAmount + _amount;
        emit Withdraw(_msgSender(), _amount);
    }

    function setWithdrawConfig(uint256 _limit, uint256 _startTime) external onlyOwner {
        require(_startTime > block.timestamp, "CertificateStaking: setWithdrawConfig: Start time must be in the future");
        require(_limit > 0, "CertificateStaking: setWithdrawConfig: Withdraw limit must be greater than 0");

        withdrawRounds[round] = RoundHistory(withdrawAmount, withdrawLimit, withdrawStartTime, block.timestamp);
        round = round + 1;
        uint256 _lastWithdrawLimit = withdrawLimit;
        uint256 _lastWithdrawStartTime = withdrawStartTime;
        withdrawLimit = _limit;
        withdrawStartTime = _startTime;
        withdrawAmount = 0;
        emit WithdrawConfig(_limit, _startTime, _lastWithdrawLimit, _lastWithdrawStartTime);
    }
}
