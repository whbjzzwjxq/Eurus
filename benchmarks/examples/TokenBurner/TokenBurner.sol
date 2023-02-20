// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract TokenBurner {
    address public _owner;
    string public constant name = "ShadowFi";
    string public constant symbol = "SDF";
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint256 public constant FIXED_FEE = 10; // 10%

    mapping(address => uint256) balances;

    mapping(uint256 => uint256) allowed;

    uint256 internal _totalSupply;

    constructor(uint256 totalSupply_) payable {
        _totalSupply = totalSupply_;
        balances[address(this)] = _totalSupply;
        _owner = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        uint256 key = _calculate_key(msg.sender, delegate);
        allowed[key] = numTokens;
        return true;
    }

    function burn(address account, uint256 _amount) public {
        _internalTransfer(account, DEAD, _amount);
        _totalSupply -= _amount;
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        return _internalTransfer(msg.sender, receiver, numTokens);
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        uint256 key = _calculate_key(owner, msg.sender);
        require(numTokens <= allowed[key]);
        allowed[key] -= numTokens;
        return _internalTransfer(owner, buyer, numTokens);
    }

    function _internalTransfer(
        address _from,
        address _to,
        uint256 numTokens
    ) internal returns (bool) {
        require(numTokens <= balances[_from]);
        balances[_from] -= numTokens;
        balances[_to] += numTokens;
        return true;
    }

    function mint(address delegate, uint256 numTokens) public {
        require(msg.sender == _owner);
        balances[delegate] += numTokens;
        _totalSupply += numTokens;
    }

    function getTokenPrice() public view returns (uint256) {
        return
            ((_totalSupply * (100 + FIXED_FEE)) / 100) /
            (address(this).balance + 1 ether);
    }

    function getETHPrice() public view returns (uint256) {
        return
            ((address(this).balance * (100 + FIXED_FEE)) / 100) /
            (_totalSupply + 1 ether);
    }

    function swapETH(uint256 tokenAmount) public payable {
        uint256 ETHRequired = tokenAmount * getETHPrice();
        require(msg.value >= ETHRequired, "Swap too much tokens!");
        bool succeed = transfer(msg.sender, tokenAmount);
        require(succeed, "Transfer failed!");
    }

    function swapToken(uint256 ETHAmount) public {
        uint256 tokenRequired = ETHAmount * getTokenPrice();
        bool succeed = _internalTransfer(msg.sender, address(this), tokenRequired);
        require(succeed, "Transfer failed!");
        payable(msg.sender).transfer(ETHAmount);
    }

    function _calculate_key(address _from, address _to) internal pure returns (uint256) {
        return uint256(uint160(_from)) << 160 + uint160(_to);
    }

    function _check(address attacker, uint256 amount) public view {
        if (attacker.balance < amount) {
            revert();
        }
    }
}
