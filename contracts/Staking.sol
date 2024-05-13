// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";


contract Staking is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public stakeToken;
    address public rewardToken;

    uint256 public startTime;
    uint256 public endTime;
    uint256 public withdrawDelay;

    uint256 public rewardPerTokenPerSecond;
    uint256 public hardCap;
    uint256 public stakedValue;
    uint256 public version = 1;

    uint256 public userAmount;
    uint256 public rewardTokenAmount;
    mapping(address => bool) private stakedUser;

    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastUpdateTime;
    mapping(address => uint256) private reward;

    event StakeEvent(address addr, uint amount);
    event UnStakeEvent(address addr, uint amount);
    event RedeemEvent(address addr, uint amount);
    event WithdrawEvent(address addr, uint amount);

    constructor(
        address _stakeToken,
        address _rewardToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _hardCap
    ) Ownable(msg.sender) {
        stakeToken = _stakeToken;
        rewardToken = _rewardToken;
        startTime = _startTime;
        endTime = _endTime;
        hardCap = _hardCap;
    }

    modifier update(address account) {
        reward[account] = available(account);
        lastUpdateTime[account] = block.timestamp;
        _;
    }

    function available(address account) public view returns (uint256) {
        uint256 _lastUpdateTime = lastUpdateTime[account];
        uint256 _currentTime = block.timestamp;
        if (_lastUpdateTime < startTime) {
            _lastUpdateTime = startTime;
        }
        if (_currentTime > endTime) {
            _currentTime = endTime;
        }
        if (_currentTime <= _lastUpdateTime) {
            return reward[account];
        }
        uint256 timeElapsed = _currentTime - _lastUpdateTime;
        uint256 earned = balanceOf[account] * timeElapsed * rewardPerTokenPerSecond / (10 ** IERC20Metadata(stakeToken).decimals());
        return reward[account] + earned;
    }

    function stake(uint256 amount) external update(_msgSender()) nonReentrant whenNotPaused {
        require(block.timestamp < endTime, "Cannot stake. Stake is over");
        require(IERC20(stakeToken).allowance(_msgSender(), address(this)) >= amount, "StakingFund doesn't have enough allowance");
        require(amount + stakedValue <= hardCap, "Exceeds maximum stake amount");
        stakedValue += amount;
        IERC20(stakeToken).safeTransferFrom(_msgSender(), address(this), amount);
        balanceOf[_msgSender()] += amount;
        if (!stakedUser[_msgSender()]) {
            stakedUser[_msgSender()] = true;
            userAmount += 1;
        }
        emit StakeEvent(_msgSender(), amount);
    }

    function unstake(uint256 amount) external update(_msgSender()) nonReentrant {
        require(amount <= balanceOf[_msgSender()], "Exceeds balance");
        balanceOf[_msgSender()] -= amount;
        stakedValue -= amount;
        IERC20(stakeToken).safeTransfer(_msgSender(), amount);
        emit UnStakeEvent(_msgSender(), amount);
    }

    function redeem() external update(_msgSender()) nonReentrant whenNotPaused {
        require(block.timestamp > endTime, "Cannot Redeem.");
        uint256 amount = reward[_msgSender()];
        require(amount > 0, "Nothing to redeem");
        reward[_msgSender()] = 0;
        IERC20(rewardToken).safeTransfer(_msgSender(), amount);
        emit RedeemEvent(_msgSender(), amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setHardCap(uint256 _hardCap) external onlyOwner {
        hardCap = _hardCap;
    }

    function setRewardPerTokenPerSecond() external onlyOwner {
        rewardTokenAmount = IERC20(rewardToken).balanceOf(address(this));
        rewardPerTokenPerSecond = (10 ** IERC20Metadata(stakeToken).decimals()) * IERC20(rewardToken).balanceOf(address(this)) / hardCap / (endTime - startTime);
    }

    function setWithdrawDelay(uint256 _withdrawDelay) external onlyOwner {
       withdrawDelay = _withdrawDelay;
    }

    function setVersion(uint256 _version) external onlyOwner {
        version = _version;
    }

    function withdraw(address token) external onlyOwner {
        require(block.timestamp >= endTime + withdrawDelay, "Cannot withdraw");
        require(token != stakeToken, "Cannot withdraw stake token");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(_msgSender(), amount);
        emit WithdrawEvent(_msgSender(), amount);
    }
}