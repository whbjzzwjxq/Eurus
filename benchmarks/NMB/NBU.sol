/**
 *Submitted for verification at BscScan.com on 2021-06-09
*/

pragma solidity ^0.8.0;

contract NBU {
    string public constant name = "Nimbus Wrapped BNB";
    string public constant symbol = "NBU_WBNB";
    uint8  public constant decimals = 18;

    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    mapping (address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;

    uint256 public _totalSupply = 100000 ether;

    constructor() {
        balanceOf[msg.sender] = _totalSupply;
    }
    
    receive() payable external {
        deposit();
    }
    
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw(uint wad) external {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        (bool success, ) = msg.sender.call{value:wad}(new bytes(0));
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

    function transferFrom(address src, address dst, uint wad) public returns (bool) {
        require(balanceOf[src] >= wad);
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }
        balanceOf[src] -= wad;
        balanceOf[dst] += wad;
        emit Transfer(src, dst, wad);
        return true;
    }    
}
