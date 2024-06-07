pragma solidity ^0.8.0;

interface ISafeswapCallee {
    function safeswapCall(address sender, uint amount0, uint amount1, bytes calldata data) external;
}
