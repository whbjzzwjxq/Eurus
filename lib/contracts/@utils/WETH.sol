// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract WETH is IERC20 {
    string public constant name = "WrappedETH";
    string public constant symbol = "WETH";

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 internal _totalSupply;
    uint8 public constant decimals = 18;

    constructor(uint256 totalSupply_) {
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(amount <= balances[msg.sender]);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256) {
        return allowed[owner][spender];
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool) {
        require(amount <= balances[from]);
        require(amount <= allowed[from][msg.sender]);

        balances[from] -= amount;
        allowed[from][msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(from, to, amount);
        return true;
    }
}
