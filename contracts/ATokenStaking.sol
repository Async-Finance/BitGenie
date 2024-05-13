pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BITGENIEBTC is IERC20, IERC20Metadata, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return 18;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

contract Staking is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public stakeToken;
    uint256 public stakeDays;
    uint256 public stakeEndtime;
    uint256 public rewardonedayonetoken;

    uint256 public hardCap;
    uint256 public stakedValue;
    uint256 public version = 'solvbtc to bitgeniebtc';

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
        uint256 _stakeDays,
        uint256 _hardCap
        uint256 _stakeEndtime;
        uint256 _rewardonedayonetoken;
    ) Ownable(msg.sender) {
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        bitgeniebtc = new BITGENIEBTC("BITGENIEBTC","BITGENIEBTC")
        stakeDays = _stakeDays;
        stakeEndtime = _stakeEndtime
        hardCap = _hardCap;
        rewardonedayonetoken = _rewardonedayonetoken
    }


    function stake(uint256 amount) external nonReentrant whenNotPaused {
        require(block.timestamp < stakeEndtime, "Cannot stake. Stake is over");
        require(stakeToken.allowance(_msgSender(), address(this)) >= amount, "StakingFund doesn't have enough allowance");
        require(amount + stakedValue <= hardCap, "Exceeds maximum stake amount");
        stakedValue += amount;
        stakeToken.safeTransferFrom(_msgSender(), address(this), amount);
        balanceOf[_msgSender()] += amount;
        if (!stakedUser[_msgSender()]) {
            stakedUser[_msgSender()] = true;
            userAmount += 1;
        }
        emit StakeEvent(_msgSender(), amount);
    }

    function unstake(uint256 amount) external nonReentrant {
        require(amount <= balanceOf[_msgSender()], "Exceeds balance");
        require(block.timestamp > stakeEndtime + stakeDays*86400, "Cannot unstake. ");
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

    function withdraw(address token) external onlyOwner {
        require(block.timestamp >= endTime + withdrawDelay, "Cannot withdraw");
        require(token != stakeToken, "Cannot withdraw stake token");
        uint256 amount = IERC20(token).balanceOf(address(this));
        IERC20(token).safeTransfer(_msgSender(), amount);
        emit WithdrawEvent(_msgSender(), amount);
    }
}