// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BZXiToken {
    uint256 internal _totalSupply;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) internal balances;

    constructor() {
        _totalSupply = 1000 ether;
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }

    function approve(address spender, uint256 amount) external {
        require(spender != address(0));
        allowed[msg.sender][spender] = amount;
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[msg.sender], "Not enough balance.");
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_from != address(0), "Null address given!");
        require(_to != address(0), "Null address given!");
        require(_value <= allowed[_from][msg.sender], "Not enough approval.");
        allowed[_from][msg.sender] -= _value;

        require(_value <= balances[_from], "Not enough balance.");

        uint256 _balancesFrom = balances[_from];
        uint256 _balancesTo = balances[_to];

        uint256 _balancesFromNew = _balancesFrom - _value;
        balances[_from] = _balancesFromNew;

        uint256 _balancesToNew = _balancesTo + _value;
        balances[_to] = _balancesToNew;

        return true;
    }

    function _check(address attacker, uint256 amount) public view {
        if (balances[attacker] < amount) {
            revert();
        }
    }
}
