// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MintableToken is IERC20 {
    address private _owner;
    string public constant name = "ROIToken";
    string public constant symbol = "ROI";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowed;

    uint256 internal _totalSupply;

    constructor(uint256 totalSupply_) payable {
        _totalSupply = totalSupply_;
        balances[msg.sender] = _totalSupply;
        _owner = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens)
        public
        returns (bool)
    {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        return true;
    }

    function approve(address delegate, uint256 numTokens)
        public
        returns (bool)
    {
        allowed[msg.sender][delegate] = numTokens;
        return true;
    }

    function allowance(address owner, address delegate)
        public
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) public returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        return true;
    }

    function mint(address delegate, uint256 numTokens) public {
        require(msg.sender == _owner, "Only owner could mint");
        balances[delegate] += numTokens;
        _totalSupply += numTokens;
    }

    function transferOwnership(address newOwner) public {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _owner = newOwner;
    }
}
