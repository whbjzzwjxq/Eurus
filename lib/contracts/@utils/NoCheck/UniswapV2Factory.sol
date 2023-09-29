// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "@uniswapv2/contracts/interfaces/IUniswapV2Factory.sol";
import "./UniswapV2Pair.sol";

contract UniswapV2Factory is IUniswapV2Factory {
    bytes32 public constant PAIR_HASH =
        0xce02182ecbb93209a7fd5bcefd4275d1898ab8bdd1921a89c3385ba9ddfd8451;

    address public override feeTo;
    address public override feeToSetter;

    mapping(address => mapping(address => address)) public override getPair;
    address[3] public override allPairs;

    constructor(
        address _feeToSetter,
        address pair0,
        address pair1,
        address pair2
    ) {
        address token0;
        address token1;
        feeToSetter = _feeToSetter;

        allPairs[0] = pair0;
        token0 = UniswapV2Pair(pair0).token0();
        token1 = UniswapV2Pair(pair0).token1();
        getPair[token0][token1] = pair0;
        getPair[token1][token0] = pair0;

        if (pair1 != address(0x0)) {
            allPairs[1] = pair1;
            token0 = UniswapV2Pair(pair1).token0();
            token1 = UniswapV2Pair(pair1).token1();
            getPair[token0][token1] = pair1;
            getPair[token1][token0] = pair1;
        }

        if (pair2 != address(0x0)) {
            allPairs[2] = pair2;
            token0 = UniswapV2Pair(pair2).token0();
            token1 = UniswapV2Pair(pair2).token1();
            getPair[token0][token1] = pair2;
            getPair[token1][token0] = pair2;
            feeToSetter = _feeToSetter;
        }
    }

    function allPairsLength() external view override returns (uint256) {
        return allPairs.length;
    }

    function createPair(
        address tokenA,
        address tokenB
    ) external override returns (address pair) {
        // Remove this function.
        // require(tokenA != tokenB, "UniswapV2: IDENTICAL_ADDRESSES");
        // (address token0, address token1) = tokenA < tokenB
        //     ? (tokenA, tokenB)
        //     : (tokenB, tokenA);
        // require(token0 != address(0), "UniswapV2: ZERO_ADDRESS");
        // require(
        //     getPair[token0][token1] == address(0),
        //     "UniswapV2: PAIR_EXISTS"
        // ); // single check is sufficient
        // pair = address(
        //     new UniswapV2Pair{
        //         salt: keccak256(abi.encodePacked(token0, token1))
        //     }()
        // );
        // IUniswapV2Pair(pair).initialize(token0, token1);
        // getPair[token0][token1] = pair;
        // getPair[token1][token0] = pair; // populate mapping in the reverse direction
        // allPairs.push(pair);
        // emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function setFeeTo(address _feeTo) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeTo = _feeTo;
    }

    function setFeeToSetter(address _feeToSetter) external override {
        require(msg.sender == feeToSetter, "UniswapV2: FORBIDDEN");
        feeToSetter = _feeToSetter;
    }
}
