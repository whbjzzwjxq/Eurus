// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {BoringMath, BoringMath128} from "./Boring.sol";

import {BentoBoxV1} from "./BentoBoxV1.sol";

// Magic Internet Money

// ███╗   ███╗██╗███╗   ███╗
// ████╗ ████║██║████╗ ████║
// ██╔████╔██║██║██╔████╔██║
// ██║╚██╔╝██║██║██║╚██╔╝██║
// ██║ ╚═╝ ██║██║██║ ╚═╝ ██║
// ╚═╝     ╚═╝╚═╝╚═╝     ╚═╝

// BoringCrypto, 0xMerlin

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract MIM is ERC20, Ownable {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    struct Minting {
        uint128 time;
        uint128 amount;
    }

    Minting public lastMint;
    uint256 private constant MINTING_PERIOD = 24 hours;
    uint256 private constant MINTING_INCREASE = 15000;
    uint256 private constant MINTING_PRECISION = 1e5;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;
    string private _symbol;

    constructor() ERC20("MIM", "Magic Internet Money") {
        _totalSupply = 17238576213941926120365877;
    }

    function mint(address to, uint256 amount) public onlyOwner {
        uint256 totalSupply = totalSupply();
        require(to != address(0), "MIM: no mint to zero address");

        // Limits the amount minted per period to a convergence function, with the period duration restarting on every mint
        uint256 totalMintedAmount = uint256(
            lastMint.time < block.timestamp - MINTING_PERIOD
                ? 0
                : lastMint.amount
        ).add(amount);
        require(
            totalSupply == 0 ||
                totalSupply.mul(MINTING_INCREASE) / MINTING_PRECISION >=
                totalMintedAmount
        );

        lastMint.time = block.timestamp.to128();
        lastMint.amount = totalMintedAmount.to128();

        totalSupply = totalSupply + amount;
        _balances[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function mintToBentoBox(
        address clone,
        uint256 amount,
        BentoBoxV1 bentoBox
    ) public onlyOwner {
        mint(address(bentoBox), amount);
        bentoBox.deposit(
            IERC20(address(this)),
            address(bentoBox),
            clone,
            amount,
            0
        );
    }

    function burn(uint256 amount) public {
        require(amount <= _balances[msg.sender], "MIM: not enough");

        _balances[msg.sender] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}
