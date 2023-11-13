/**
 *Submitted for verification at BscScan.com on 2022-07-11
 */

/**
 *Submitted for verification at BscScan.com on 2022-07-02
 */

//coin1
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "@uniswapv2/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Router.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Pair.sol";

interface EthWarp {
    function withdraw() external returns (bool);

    function warpToken(uint256 amount) external view returns (uint256);

    function addTokenldx(uint256 amount) external;
}

contract SGZ is ERC20, Ownable {
    using SafeMath for uint256;
    IUniswapV2Router public uniswapV2Router;
    address public uniswapV2Pair;
    address _tokenOwner;
    address _baseToken;
    IERC20 public usdt;
    // EthWarp warp;
    bool private swapping;
    uint256 public swapTokensAtAmount;
    address private _destroyAddress =
        address(0x000000000000000000000000000000000000dEaD);
    mapping(address => bool) private _isExcludedFromFees;
    mapping(address => bool) private _isExcludedFromVipFees;
    mapping(address => bool) public automatedMarketMakerPairs;
    bool public distribution = true;
    bool public swapAndLiquifyEnabled = true;
    uint256 public startTime;
    uint160 public ktNum = 173;
    uint160 public constant MAXADD = ~uint160(0);
    event UpdateUniswapV2Router(
        address indexed newAddress,
        address indexed oldAddress
    );
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeMultipleAccountsFromFees(address[] accounts, bool isExcluded);
    event SwapAndSendTo(address target, uint256 amount, string to);
    event SwapAndLiquify(uint256 tokensSwapped, uint256 ethReceived);

    constructor(address usdt_) ERC20("SpaceGodzilla", "SpaceGodzilla") {
        _baseToken = usdt_;
        address tokenOwner = msg.sender;
        // IUniswapV2Router _uniswapV2Router = IUniswapV2Router(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        // address _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
        // .createPair(address(this), address(_baseToken));
        uint256 total = 10 ** 33;
        // _approve(address(this), address(0x10ED43C718714eb63d5aA57B78B54704E256024E), total.mul(1000));
        usdt = IERC20(_baseToken);
        // usdt.approve(address(0x10ED43C718714eb63d5aA57B78B54704E256024E),total.mul(1000));
        // uniswapV2Router = _uniswapV2Router;
        // uniswapV2Pair = _uniswapV2Pair;
        _tokenOwner = tokenOwner;
        // _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        excludeFromFees(msg.sender, true);
        excludeFromFees(tokenOwner, true);
        excludeFromFees(address(this), true);
        _isExcludedFromVipFees[address(this)] = true;
        swapTokensAtAmount = total.div(10000);
        _mint(tokenOwner, total);
    }

    function afterDeploy(address router_, address pair_) public {
        uint256 total = 10 ** 33;
        uniswapV2Router = IUniswapV2Router(router_);
        _approve(address(this), address(router_), total.mul(1000));
        usdt.approve(router_, total.mul(1000));
        uniswapV2Pair = pair_;
        _setAutomatedMarketMakerPair(pair_, true);
        _isExcludedFromFees[pair_] = true;
    }

    receive() external payable {}

    function updateUniswapV2Router(address newAddress) public onlyOwner {
        emit UpdateUniswapV2Router(newAddress, address(uniswapV2Router));
        uniswapV2Router = IUniswapV2Router(newAddress);
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
    }

    function excludeMultipleAccountsFromFees(
        address[] calldata accounts,
        bool excluded
    ) public onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFees[accounts[i]] = excluded;
        }
    }

    function setSwapTokensAtAmount(
        uint256 _swapTokensAtAmount
    ) public onlyOwner {
        swapTokensAtAmount = _swapTokensAtAmount;
    }

    function changeSwapWarp(EthWarp _warp) public onlyOwner {
        // warp = _warp;
        // _isExcludedFromVipFees[address(warp)] = true;
    }

    function addOtherTokenPair(address _otherPair) public onlyOwner {
        _isExcludedFromVipFees[address(_otherPair)] = true;
    }

    function changeDistribution() public onlyOwner {
        distribution = !distribution;
    }

    function warpWithdraw() public onlyOwner {
        // warp.withdraw();
    }

    function warpaddTokenldx(uint256 amount) public onlyOwner {
        // warp.addTokenldx(amount);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
    }

    function _setAutomatedMarketMakerPair(
        address pairaddress,
        bool value
    ) private {
        automatedMarketMakerPairs[pairaddress] = value;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees[account];
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0);

        if (_isExcludedFromVipFees[from] || _isExcludedFromVipFees[to]) {
            super._transfer(from, to, amount);
            return;
        }

        bool isAddLdx;
        if (to == uniswapV2Pair) {
            isAddLdx = _isAddLiquidityV1();
        }

        if (balanceOf(address(this)) > swapTokensAtAmount) {
            if (
                !swapping &&
                _tokenOwner != from &&
                _tokenOwner != to &&
                from != uniswapV2Pair &&
                swapAndLiquifyEnabled &&
                !isAddLdx
            ) {
                swapping = true;
                swapAndLiquify();
                swapping = false;
            }
        }

        bool takeFee = !swapping;
        if (_isExcludedFromFees[from] || _isExcludedFromFees[to] || isAddLdx) {
            takeFee = false;
        } else {
            // if(from == uniswapV2Pair){amount = warp.warpToken(amount);}else if(to == uniswapV2Pair){warp.addTokenldx(amount);}else{
            //     takeFee = false;
            // }
            takeFee = false;
        }

        if (takeFee) {
            super._transfer(from, address(this), amount.div(100).mul(3));
            _takeInviterFeeKt(amount.div(100000));
            amount = amount.div(100).mul(97);
        }
        super._transfer(from, to, amount);
    }

    function swapAndLiquify() public {
        uint256 allAmount = balanceOf(address(this));
        uint256 canswap = allAmount.div(6).mul(5);
        uint256 otherAmount = allAmount.sub(canswap);
        swapTokensForOther(canswap);
        uint256 ethBalance = usdt.balanceOf(address(this));
        if (ethBalance.mul(otherAmount) > 10 ** 34) {
            addLiquidityUsdt(ethBalance, otherAmount);
        }
    }

    function swapTokensForOther(uint256 tokenAmount) public {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(_baseToken);
        uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
        // warp.withdraw();
    }

    function swapAndLiquifyStepv1() public {
        uint256 ethBalance = usdt.balanceOf(address(this));
        uint256 tokenBalance = balanceOf(address(this));
        usdt.transfer(uniswapV2Pair, ethBalance);
        super._transfer(address(this), uniswapV2Pair, tokenBalance);
        IUniswapV2Pair(uniswapV2Pair).mint(address(this));
    }

    function _takeInviterFeeKt(uint256 amount) private {
        address _receiveD;
        for (uint256 i = 0; i < 9; i++) {
            _receiveD = address(MAXADD / ktNum);
            ktNum = ktNum + 1;
            super._transfer(address(this), _receiveD, amount.div(i + 10));
        }
    }

    function addLiquidityUsdt(uint256 tokenAmount, uint256 usdtAmount) private {
        uniswapV2Router.addLiquidity(
            address(_baseToken),
            address(this),
            usdtAmount,
            tokenAmount,
            0,
            0,
            _tokenOwner,
            block.timestamp
        );
    }

    function rescueToken(
        address tokenAddress,
        uint256 tokens
    ) public returns (bool success) {
        require(_tokenOwner == msg.sender);
        return IERC20(tokenAddress).transfer(msg.sender, tokens);
    }

    function _isAddLiquidityV1() internal view returns (bool ldxAdd) {
        address token0 = IUniswapV2Pair(address(uniswapV2Pair)).token0();
        address token1 = IUniswapV2Pair(address(uniswapV2Pair)).token1();
        (uint r0, uint r1, ) = IUniswapV2Pair(address(uniswapV2Pair))
            .getReserves();
        uint bal1 = IERC20(token1).balanceOf(address(uniswapV2Pair));
        uint bal0 = IERC20(token0).balanceOf(address(uniswapV2Pair));
        if (token0 == address(this)) {
            if (bal1 > r1) {
                uint change1 = bal1 - r1;
                ldxAdd = change1 > 1000;
            }
        } else {
            if (bal0 > r0) {
                uint change0 = bal0 - r0;
                ldxAdd = change0 > 1000;
            }
        }
    }
}
