pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PWISH is IERC20, IERC20Metadata, Ownable {
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

contract WISHExchange is Ownable {
    using SafeMath for uint256;

    IERC20 public wishToken;
    PWISH public pwishToken;

    uint public wishDeposits;
    uint public pwishBalances;
    uint public withdrawalAmounts;
    uint public withdrawalTimes;

    event Deposit(address indexed user, uint256 amount);
    event WithdrawalDefined(uint256 amount, uint256 time);
    event Withdrawal(address indexed user, uint256 amount);
    event Swap(address indexed user, uint256 wishAmount, uint256 pwishAmount);

    constructor(address _wishToken) {
        wishToken = IERC20(_wishToken);
        pwishToken = new PWISH("PWISH", "PWISH");
        withdrawalAmounts = 0;
        withdrawalTimes = block.timestamp + 86400 *60;

    }

    function depositWish(uint256 _amount) external {
        require(wishToken.allowance(_msgSender(), address(this)) >= amount, "DepositFund doesn't have enough allowance");
        wishDeposits += _amount;
        wishToken.transferFrom(_msgSender(), address(this), _amount);
        pwishBalances += _amount;
        pwishToken._mint(_msgSender(), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function swapPwishToWish(uint256 _amount) external {
        require(pwishToken.balanceOf[_msgSender()] >=_amount, "Insufficient pwish balance");
        require(pwishToken.allowance(_msgSender(), address(this)) > _amount, "PwishFund doesn't have enough allowance")
        require(block.timestamp >= withdrawalTimes, "Withdrawal time is wrong");
        require(_amount < wishDeposits, "pwish swap amount is wrong,wishDeposits");
        require(_amount < pwishBalances, "pwish swap amount is wrong,pwishBalances");
        require(_amount < withdrawalAmounts, "pwish swap amount is wrong,withdrawAmounts")
        pwishBalances -= _amount  
        pwishToken._burn(_msgSender(), _amount);
        wishDeposits -= _amount
        wishToken.transfer(_msgSender(), _amount);
        emit Withdrawal(msg.sender, wishAmount);
    }

    function defineWithdrawal(uint256 _amount, uint256 _time) external onlyOwner {
        withdrawalAmounts = _amount;
        withdrawalTimes = _time;
        emit WithdrawalDefined(withdrawalAmounts, withdrawalTimes);
    }
}
