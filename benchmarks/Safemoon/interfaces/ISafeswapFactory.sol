pragma solidity ^0.8.0;

interface ISafeswapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256 length);

    function feeTo() external view returns (address);

    function router() external view returns (address);
    
    function implementation() external view returns (address);

    function feeToSetter() external view returns (address);

    function isBlacklistedStatus(address account) external view returns (bool);

    function approvePartnerStatus(address account) external view returns (bool);

    function isBlacklistedToken(address account) external view returns (bool);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(
        address tokenA,
        address tokenB,
        address to
    ) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

//    function getFeeConfig() external view returns (FeeConfig memory);
//
//    function getTotalFee() external view returns (uint256, uint256);
//
//    struct FeeConfig {
//        address feeTo;
//        address buyBackWallet;
//        uint256 companyFeePercent;
//        uint256 buyBackFeePercent;
//        uint256 lpFeePercent;
//        uint256 precision;
//    }
}

