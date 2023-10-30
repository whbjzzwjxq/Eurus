// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import {IUniswapV2Pair} from "@utils/UniswapV2Pair.sol";

interface IStrategy {
    function unsalvagableTokens(address tokens) external view returns (bool);

    function underlying() external view returns (address);

    function vault() external view returns (address);

    function withdrawAllToVault() external;

    function withdrawToVault(uint256 amount) external;

    function investAllUnderlying() external;

    function investedBalance() external view returns (uint256); // itsNotMuch()

    function strategyEnabled(address) external view returns (bool);

    // should only be called by controller
    function salvage(address recipient, address token, uint256 amount) external;

    function doHardWork() external;

    function harvest(uint256 _denom, address sender) external;

    function depositArbCheck() external view returns (bool);

    // new functions
    function investedBalanceInUSD() external view returns (uint256);

    function withdrawAllToVault(address _underlying) external;

    function withdrawToVault(uint256 _amount, address _underlying) external;

    function assetToUnderlying(address _asset) external returns (uint256);

    function getUSDBalanceFromUnderlyingBalance(
        uint256 _bal
    ) external view returns (uint256 _amount);
}

contract Strategy is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct StrategyInfo {
        address strategy;
        uint256 allocPoint;
    }

    address public vault;
    address public pair;
    address public usdce;

    uint256 public init_balance;

    uint256 public _investedBalanceInUSD = 4448686168141524586181482;

    StrategyInfo[] public strategyInfo;
    uint256 public totalAllocPoint;
    mapping(address => bool) public strategyEnabled;

    constructor() {}

    function afterDeploy(address vaultAddr, address pairAddr, address usdceAddr) public {
        vault = vaultAddr;
        pair = pairAddr;
        usdce = usdceAddr;
        init_balance = IERC20(usdce).balanceOf(address(this));
    }

    // function initialize(address _vault) public initializer {
    //     __Ownable_init();
    //     vault = _vault;
    // }

    modifier restricted() {
        require(
            msg.sender == vault || msg.sender == owner(),
            "The sender has to be the owner or vault"
        );
        _;
    }

    function addStrategy(
        uint256 _allocPoint,
        address _strategy
    ) public onlyOwner {
        require(_strategy != address(0), "strategy must be defined");
        require(!strategyEnabled[_strategy], "strategy already enabled");

        strategyInfo.push(
            StrategyInfo({strategy: _strategy, allocPoint: _allocPoint})
        );
        strategyEnabled[_strategy] = true;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
    }

    function setStrategy(uint256 _sid, uint256 _allocPoint) public onlyOwner {
        totalAllocPoint = totalAllocPoint
            .sub(strategyInfo[_sid].allocPoint)
            .add(_allocPoint);
        strategyInfo[_sid].allocPoint = _allocPoint;
    }

    function enableStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "strategy must be defined");
        require(!strategyEnabled[_strategy], "strategy already enabled");
        strategyEnabled[_strategy] = true;
    }

    function disableStrategy(address _strategy) external onlyOwner {
        require(_strategy != address(0), "strategy must be defined");
        require(strategyEnabled[_strategy], "strategy already disabled");
        strategyEnabled[_strategy] = false;
    }

    // function investedBalanceInUSD() public view returns (uint256 _balance) {
    //     uint256 _length = strategyInfo.length;
    //     for (uint256 _sid = 0; _sid < _length; _sid++) {
    //         _balance = _balance.add(
    //             IStrategy(strategyInfo[_sid].strategy).investedBalanceInUSD()
    //         );
    //     }
    //     // Hardcode
    //     return 0x00000000000000000000000000000000000000000003ae0bc2aa3f3a0eebb36a;
    // }

    // function assetToUnderlying(address _inputAsset) public returns (uint256) {
    //     uint256 _totalDeposited;
    //     uint256 _length = strategyInfo.length;
    //     uint256 _inputBalance = IERC20(_inputAsset).balanceOf(address(this));

    //     if (_inputBalance == 0) {
    //         return 0;
    //     }

    //     for (uint256 _sid = 0; _sid < _length; _sid++) {
    //         StrategyInfo storage _strategyInfo = strategyInfo[_sid];

    //         if (strategyEnabled[_strategyInfo.strategy]) {
    //             uint256 _balanceToDeposit = _inputBalance
    //                 .mul(_strategyInfo.allocPoint)
    //                 .div(totalAllocPoint);

    //             if (_sid == _length - 1) {
    //                 _balanceToDeposit = IERC20(_inputAsset).balanceOf(
    //                     address(this)
    //                 );
    //             }

    //             IERC20(_inputAsset).safeTransfer(
    //                 _strategyInfo.strategy,
    //                 _balanceToDeposit
    //             );

    //             uint256 _added = IStrategy(strategyInfo[_sid].strategy)
    //                 .assetToUnderlying(_inputAsset);

    //             uint256 _addedInUSD = IStrategy(strategyInfo[_sid].strategy)
    //                 .getUSDBalanceFromUnderlyingBalance(_added);
    //             _totalDeposited = _totalDeposited.add(_addedInUSD);
    //         }
    //     }

    //     return _totalDeposited;
    // }

    function assetToUnderlying(address _inputAsset) public returns (uint256) {
        // Hardcode
        uint256 price = 0.557 ether;
        uint256 percent = 76;
        uint256 usd_decimal = 1e6;
        uint256 assetDelta = ERC20(_inputAsset).balanceOf(address(this)) - init_balance;
        uint256 assetInUSD = assetDelta * price / usd_decimal;
        _investedBalanceInUSD += assetInUSD * (1000 + percent) / 1000;
        return assetInUSD;
    }

    function investedBalanceInUSD() public view returns (uint256) {
        return _investedBalanceInUSD;
    }

    function doHardWork() public restricted {
        for (uint256 _sid = 0; _sid < strategyInfo.length; _sid++) {
            if (
                strategyEnabled[strategyInfo[_sid].strategy] &&
                strategyInfo[_sid].allocPoint > 0
            ) {
                IStrategy(strategyInfo[_sid].strategy).doHardWork();
            }
        }
    }

    function salvage(
        address recipient,
        address token,
        uint256 amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(recipient, amount);
    }

    function withdrawAllToVault(address _asset) public restricted {
        for (uint256 _sid = 0; _sid < strategyInfo.length; _sid++) {
            IStrategy(strategyInfo[_sid].strategy).withdrawAllToVault();
        }
    }

    function withdrawToVault(
        uint256 _usdAmount,
        address _asset
    ) external restricted {
        // uint256 _totalBalance = investedBalanceInUSD();

        // require(_totalBalance > 0, "No invested balance");
        // uint256 _ratio = _usdAmount.mul(1e36).div(_totalBalance);

        // for (uint256 _sid = 0; _sid < strategyInfo.length; _sid++) {
        //     StrategyInfo storage _strategyInfo = strategyInfo[_sid];
        //     address _strategy = _strategyInfo.strategy;
        //     uint256 _strategyBal = IStrategy(_strategy).investedBalanceInUSD();
        //     uint256 _amountToWithdraw = _strategyBal.mul(_ratio).div(1e36);

        //     IStrategy(_strategy).withdrawToVault(_amountToWithdraw, _asset);
        // }
        // Hardcode
        uint256 price = 0.557 ether;
        uint256 percent = 76;
        uint256 usd_decimal = 1e6;
        uint256 assetAmount = _usdAmount / price * usd_decimal;
        _investedBalanceInUSD -= assetAmount * (1000 + percent) / 1000;
        IERC20(_asset).safeTransfer(vault, assetAmount);
    }

    function strategyLength() external view returns (uint256) {
        return strategyInfo.length;
    }
}
