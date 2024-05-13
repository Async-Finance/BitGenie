pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PWISH is IERC20, IERC20Metadata, Ownable {

   
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }
}

contract WISHExchange is Ownable {
    

    IERC20 public wishToken;
    PWISH public pwishToken;

    uint public wishDeposits;
    uint public pwishBalances;
    uint public withdrawalAmounts;
    uint public withdrawalTimes;

    event Deposit(address indexed user, uint256 amount);
    event WithdrawalDefined(uint256 amount, uint256 time);
    event Withdrawal(address indexed user, uint256 amount);
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
        require(pwishToken.allowance(_msgSender(), address(this)) > _amount, "PwishFund doesn't have enough allowance");
        require(block.timestamp >= withdrawalTimes, "Withdrawal time is not start");
        require(_amount < wishDeposits, "pwish swap amount is wrong,wishDeposits");
        require(_amount < pwishBalances, "pwish swap amount is wrong,pwishBalances");
        require(_amount < withdrawalAmounts, "pwish swap amount is wrong,withdrawAmounts");
        require(withdrawalAmounts >0, "no enough wish to swap");
        pwishBalances -= _amount;
        pwishToken._burn(_msgSender(), _amount);
        wishDeposits -= _amount;
        wishToken.transfer(_msgSender(), _amount);
        emit Withdrawal(msg.sender, _amount);
    }

    function defineWithdrawal(uint256 _amount, uint256 _time) external onlyOwner {
        require(_amount < wishDeposits, 'no enough wish');
        withdrawalAmounts = _amount;
        withdrawalTimes = _time;
        emit WithdrawalDefined(withdrawalAmounts, withdrawalTimes);
    }
}
