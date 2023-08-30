// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.0;

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// contract BurningToken is IERC20 {
//     string public constant name = "BurningToken";
//     string public constant symbol = "BT";
//     address public _owner;
//     address public constant DEAD = address(0xdead);

//     mapping(address => uint256) balances;

//     mapping(address => mapping(address => uint256)) allowed;

//     uint256 internal _totalSupply;

//     constructor(uint256 totalSupply_) {
//         _totalSupply = totalSupply_;
//         balances[msg.sender] = _totalSupply;
//         _owner = msg.sender;
//     }

//     function owner() public view virtual returns (address) {
//         return _owner;
//     }

//     modifier onlyOwner() {
//         require(owner() == msg.sender, "Ownable: caller is not the owner");
//         _;
//     }

//     function setOwner (address newOwner) public onlyOwner {
//         _owner = newOwner; 
//     }

//     function totalSupply() external view returns (uint256) {
//         return _totalSupply;
//     }

//     function balanceOf(address tokenOwner) external view returns (uint256) {
//         return balances[tokenOwner];
//     }

//     function transfer(address to, uint256 amount) external returns (bool) {
//         require(amount <= balances[msg.sender]);
//         _internalTransfer(msg.sender, to, amount);
//         emit Transfer(msg.sender, to, amount);
//         return true;
//     }

//     function allowance(
//         address holder,
//         address spender
//     ) external view returns (uint256) {
//         return allowed[holder][spender];
//     }

//     function approve(address spender, uint256 amount) external returns (bool) {
//         allowed[msg.sender][spender] = amount;
//         emit Approval(msg.sender, spender, amount);
//         return true;
//     }

//     function transferFrom(
//         address from,
//         address to,
//         uint256 amount
//     ) external returns (bool) {
//         require(amount <= balances[from]);
//         require(amount <= allowed[from][msg.sender]);

//         allowed[from][msg.sender] -= amount;
//         _internalTransfer(from, to, amount);

//         emit Transfer(from, to, amount);
//         return true;
//     }

//     function _burn(address spender, uint256 amount) internal {
//         _internalTransfer(spender, DEAD, amount);
//         _totalSupply -= amount;
//     }

//     function burn(address spender, uint256 amount) public {
//         _burn(spender, amount);
//     }

//     function _mint(address spender, uint256 amount) internal {
//         balances[spender] += amount;
//         _totalSupply += amount;
//     }

//     function _internalTransfer(
//         address _from,
//         address _to,
//         uint256 _amount
//     ) internal returns (bool) {
//         require(_amount <= balances[_from]);
//         balances[_from] -= _amount;
//         balances[_to] += _amount;
//         return true;
//     }
// }
