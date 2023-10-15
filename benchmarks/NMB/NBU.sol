/**
 *Submitted for verification at BscScan.com on 2021-06-09
 */

pragma solidity ^0.8.0;

contract NBU {
    string public constant name = "Nimbus Wrapped BNB";
    string public constant symbol = "NBU_WBNB";
    uint8 public constant decimals = 18;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    mapping(address => uint) public _balances;
    mapping(address => mapping(address => uint)) public allowance;

    uint256 public _totalSupply = 100000 ether;

    constructor() {
        _balances[msg.sender] = _totalSupply;
    }

    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint wad) external {
        require(_balances[msg.sender] >= wad);
        _balances[msg.sender] -= wad;
        (bool success, ) = msg.sender.call{value: wad}(new bytes(0));
        require(success, "NBU_WBNB: Transfer failed");
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() external view returns (uint) {
        return address(this).balance + _totalSupply;
    }

    function approve(address guy, uint wad) external returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) external returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint wad
    ) public returns (bool) {
        require(_balances[src] >= wad);
        if (
            src != msg.sender && allowance[src][msg.sender] != type(uint256).max
        ) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        _balances[src] -= wad;
        _balances[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
}
