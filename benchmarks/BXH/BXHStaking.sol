/**
 *Submitted for verification at BscScan.com on 2022-09-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "@uniswapv2/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Router.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Pair.sol";

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferNative(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: Native_TRANSFER_FAILED');
    }
}

//providing delegated tokenstakingpool
//need check the delegated right.
contract BXHStaking is Ownable, ReentrancyGuard{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    using EnumerableSet for EnumerableSet.AddressSet;

    // Info of each user.
    struct UserInfo {
        uint256 amount;     // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt.
        uint256 rewardReceived; //Reward received
        uint256 lastReceived;
    }

    struct DepositOrder {
        uint256 orderTime;
        uint256 amount;
    }

    mapping(uint256 => mapping(address => DepositOrder[])) public userDepositInfo;

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;           // Address of LP token contract.
        uint256 allocPoint;       // How many allocation points assigned to this pool. Tokens to distribute per block.
        uint256 lastRewardBlock;  // Last block number that Tokens distribution occurs.
        uint256 accITokenPerShare; // Accumulated Tokens per share, times 1e12.
        uint256 totalAmount;    // Total amount of current pool deposit.
        
        uint256 lockSeconds;    //After lock seconds can release to withdraw

        bool  enableBonus;
        address bonusToken;

        //use the swap pair to caculate bonustoken swap ratio, need check the pair price.
        address swapPairAddress;

        uint256 depositMin;   //deposit limitation of one time
        uint256 depositMax;   //
    }

    // The Platform Token!
    IERC20 public iToken;

    // Bonus tokens created per block.
    uint256 public tokenPerBlock;

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    
    // Control mining
    bool public paused = false;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;

    // The block number when Tokens mining starts.
    uint256 public startBlock;

    // define blocks are decreased.
    uint256 public decayPeriod = 30*24*1200; //defaut blocks: 30 days.
    uint256 public decayRatio = 970;    //default : 3%

    uint256 []public decayTable;

    // adminAddress:  suggest using multisign address.
    address public adminAddress;
    
    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);
    
    event PoolAdded(uint256 _pid, uint256 _allocPoint, IERC20 _lpToken,bool _enableBonus, address _bonusToken, address _swapPairAddress, uint256 _lockSeconds , uint256 _depositMin, uint256 _depositMax);
    event PoolBonusChanged(uint256 _pid, bool _enableBonus, address _bonusToken, address _swapPairAddress, uint256 _lockSeconds);
    event PoolDepositChanged(uint256 _pid, uint256 _depositMin, uint256 _depositMax);
    event PoolAllocateChanged(uint256 _pid, uint256 _allocPoint);

    event DepositDelegate(address indexed user,address toUser, uint256 indexed pid, uint256 amount);

    //switch delegate
    bool public openDelegate;
    address public delegateCaller;
    event SetDelegate(bool ,address );

    constructor(
        address _iToken,
        uint256 _tokenPerBlock, 
        uint256 _startBlock,
        uint256 _decayRatio,
        address _adminAddress
    )  {
        iToken = IERC20(_iToken);
        tokenPerBlock = _tokenPerBlock;
        startBlock = _startBlock;
        decayRatio = _decayRatio;
        decayTable.push(_tokenPerBlock); 
        
        for(uint256 i=0;i<32;i++) {
            decayTable.push(decayTable[i].mul(decayRatio).div(1000));
        }

        adminAddress = _adminAddress;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "need admin right.");
        _;
    }

    // Update admin address by the owner.
    function setAdmin(address _adminAddress) public onlyOwner {
        adminAddress = _adminAddress;
    }

    //set delegate info by the owner.
    function setDelegate( bool open, address caller ) public onlyOwner{
        openDelegate = open;
        delegateCaller = caller;

        emit SetDelegate( open, caller);
    }

    modifier notPause() {
        require(paused == false, "Mining has been suspended");
        _;
    }

    function setPause( bool _paused ) public onlyOwner {
        paused = _paused;
    }

    function setDecayPeriod(uint256 _block) public onlyAdmin {
        decayPeriod = _block;
    }

	function setDecayRatio(uint256 _ratio) public onlyAdmin {
		require(_ratio<=1000,"ratio should less than 1000");
        decayRatio = _ratio;
    }

    // Set the number of token produced by each block
    function setTokenPerBlock(uint256 _newPerBlock) public onlyAdmin {
        massUpdatePools();
        tokenPerBlock = _newPerBlock;
    }

    // Set the pid of pool 
    function setBonus(uint256 _pid, bool _enableBonus, address _bonusToken, address _swapPairAddress, uint256 _lockSeconds ) public onlyAdmin{
        require( _pid < poolInfo.length, "pid is invalid");

        PoolInfo storage pool = poolInfo[_pid];

        pool.enableBonus = _enableBonus;
        pool.bonusToken = _bonusToken;
        pool.swapPairAddress = _swapPairAddress;

        pool.lockSeconds = _lockSeconds;

        require(IUniswapV2Pair(pool.swapPairAddress).token0() == address(iToken) || IUniswapV2Pair(pool.swapPairAddress).token1() == address(iToken), "iToken is not exist");

        require(IUniswapV2Pair(pool.swapPairAddress).token0() == _bonusToken || IUniswapV2Pair(pool.swapPairAddress).token1() == _bonusToken, "bonus is not exist");

        emit PoolBonusChanged(_pid, _enableBonus, _bonusToken, _swapPairAddress, _lockSeconds);
    }

    // Set the pid of pool 
    function setPoolDepositLimited(uint256 _pid, uint256 _depositMin, uint256 _depositMax ) public onlyAdmin{
        require( _pid < poolInfo.length, "pid is invalid");

        require( _depositMax >= _depositMin, "limit error");

        PoolInfo storage pool = poolInfo[_pid];

        pool.depositMin = _depositMin;
        pool.depositMax = _depositMax;

        emit PoolDepositChanged(_pid, _depositMin, _depositMax);

    }


    function getITokenBonusAmount( uint256 _pid, uint256 _amountInToken ) public view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];

        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(pool.swapPairAddress).getReserves();
        uint256 amountTokenOut = 0; 
        uint256 _fee = 0;
        if(IUniswapV2Pair(pool.swapPairAddress).token0() == address(iToken)){
            amountTokenOut = getAmountOut( _amountInToken , _reserve0, _reserve1, _fee);
        } else {
            amountTokenOut = getAmountOut( _amountInToken , _reserve1, _reserve0, _fee);
        }
        return amountTokenOut;
    }

    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, uint256 feeFactor) private pure returns (uint ) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');

        uint256 feeBase = 1000;

        uint amountInWithFee = amountIn.mul(feeBase.sub(feeFactor));
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(feeBase).add(amountInWithFee);
        uint amountOut = numerator / denominator;
        return amountOut;
    }

    function poolLength() public view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new lp to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do.
    function add(uint256 _allocPoint, IERC20 _lpToken,bool _enableBonus, address _bonusToken, address _swapPairAddress, uint256 _lockSeconds , uint256 _depositMin, uint256 _depositMax, bool _withUpdate) public onlyAdmin {
        require(address(_lpToken) != address(0), "_lpToken is the zero address");

        if( _enableBonus == true ){
            require(address(_bonusToken) != address(0), "bonus token is the zero address.");
            require(address(_swapPairAddress) != address(0), "Price Pair is the zero address.");
        }

        require( _depositMax >= _depositMin, "limit error");

        if (_withUpdate) {
            massUpdatePools();
        }

        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;

        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken : _lpToken,
            allocPoint : _allocPoint,
            lastRewardBlock : lastRewardBlock,
            accITokenPerShare : 0,
            totalAmount : 0,
            enableBonus : _enableBonus,
            bonusToken : _bonusToken ,
            swapPairAddress : _swapPairAddress,
            lockSeconds : _lockSeconds,
            depositMin : _depositMin,
            depositMax : _depositMax
        }));

        uint256 _pid = poolLength() - 1;

        emit PoolAdded(_pid, _allocPoint, _lpToken, _enableBonus, _bonusToken, _swapPairAddress, _lockSeconds, _depositMin, _depositMax);
    }

    // Update the given pool's IToken allocation point. Can only be called by the owner.
    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyAdmin {
        require(_pid <= poolLength() - 1, "not find this pool");
        
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;

        emit PoolAllocateChanged(_pid, _allocPoint);
    }

    //query the phose of mining pool.
    function phase(uint256 blockNumber) public view returns (uint256) {
        if (decayPeriod == 0) {
            return 0;
        }
        if (blockNumber > startBlock) {
            return (blockNumber.sub(startBlock).sub(1)).div(decayPeriod);
        }
        return 0;
    }

    function rewardV(uint256 blockNumber) public view returns (uint256) {
        uint256 _phase = phase(blockNumber);
        require(_phase<decayTable.length,"phase not ready");
        return decayTable[_phase];
    }

    //batch extend the decaytable data.
	function batchPrepareRewardTable(uint256 spareCount) public returns (uint256) {
		require(spareCount<64,"spareCount too large , must less than 64");
        uint256 _phase = phase(block.number);
        if( _phase.add(spareCount) >= decayTable.length){
        	uint256 loop = _phase.add(spareCount).sub(decayTable.length);
	        for(uint256 i=0;i<=loop;i++) {
	        	uint256 lastDecayValue = decayTable[decayTable.length-1];
	     		decayTable.push(lastDecayValue.mul(decayRatio).div(1000));
	     	}
        }
        return decayTable[_phase];
    }

    function safePrepareRewardTable(uint256 blockNumber)  internal returns (uint256) {
        uint256 _phase = phase(blockNumber);       
        if( _phase >= decayTable.length){
        	uint256 lastDecayValue = decayTable[decayTable.length-1];
	     	decayTable.push(lastDecayValue.mul(decayRatio).div(1000));
        }
        return decayTable[_phase];
    }

    function getITokenBlockRewardV(uint256 _lastRewardBlock) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(block.number);
        while (n < m) {
            n++;
            uint256 r = n.mul(decayPeriod).add(startBlock);
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(rewardV(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(rewardV(block.number)));
        return blockReward;
    }


    function getITokenBlockRewardV(uint256 _lastRewardBlock,uint256 blocknumber) public view returns (uint256) {
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(blocknumber);
        while (n < m) {
            n++;
            uint256 r = n.mul(decayPeriod).add(startBlock);
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(rewardV(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((blocknumber.sub(_lastRewardBlock)).mul(rewardV(blocknumber)));
        return blockReward;
    }

    function safeGetITokenBlockReward(uint256 _lastRewardBlock) public returns (uint256) {
        uint256 blockReward = 0;
        uint256 n = phase(_lastRewardBlock);
        uint256 m = phase(block.number);
        while (n < m) {
            n++;
            uint256 r = n.mul(decayPeriod).add(startBlock);
            blockReward = blockReward.add((r.sub(_lastRewardBlock)).mul(safePrepareRewardTable(r)));
            _lastRewardBlock = r;
        }
        blockReward = blockReward.add((block.number.sub(_lastRewardBlock)).mul(safePrepareRewardTable(block.number)));
        return blockReward;
    }


    // Update reward variables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply;
        lpSupply = pool.totalAmount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }

        uint256 blockReward = safeGetITokenBlockReward(pool.lastRewardBlock);
        if (blockReward <= 0) {
            return;
        }

        uint256 iTokenReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);

        pool.accITokenPerShare = pool.accITokenPerShare.add(iTokenReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // View function to see pending ITokens on frontend.
    function pending(uint256 _pid, address _user) external view returns (uint256, uint256){
        uint256 iTokenAmount = pendingIToken(_pid, _user);
        return (iTokenAmount, 0);
    }

    function lockedToken(uint256 _pid, address _user) external view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];

        uint256 lockedAmount = 0;
        DepositOrder[] memory orders = userDepositInfo[_pid][_user];
        uint256 len = orders.length;
        uint256 checkTime = block.timestamp;

        for (uint256 i = 0; i < len; i++) {
            if( orders[i].orderTime.add(pool.lockSeconds) > checkTime ){
                lockedAmount = lockedAmount.add( orders[i].amount);
            }
        }

        return lockedAmount;
    }

    function pendingIToken(uint256 _pid, address _user) private view returns (uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accITokenPerShare = pool.accITokenPerShare;
        uint256 lpSupply = pool.totalAmount;
        if (user.amount > 0) {
            if (block.number > pool.lastRewardBlock) {
                uint256 blockReward = getITokenBlockRewardV(pool.lastRewardBlock);
                uint256 bxhReward = blockReward.mul(pool.allocPoint).div(totalAllocPoint);
                accITokenPerShare = accITokenPerShare.add(bxhReward.mul(1e12).div(lpSupply));
                return user.amount.mul(accITokenPerShare).div(1e12).sub(user.rewardDebt);
            }
            if (block.number == pool.lastRewardBlock) {
                return user.amount.mul(accITokenPerShare).div(1e12).sub(user.rewardDebt);
            }
        }
        return 0;
    }

    //get all pending reward
    function pendingAllReward( address _user) external view returns (uint256, uint256){
        if(poolInfo.length == 0){
            return (0, 0);
        }

        uint256 iTokenAmountTotal ;
        uint256 tokenAmountTotal;
        uint256 len = poolInfo.length;
        for (uint256 _pid = 0; _pid < len; _pid++) {
            UserInfo storage user = userInfo[_pid][ _user];
            if( user.amount > 0 ){
                uint256 iTokenAmount = pendingIToken(_pid, _user);
                iTokenAmountTotal = iTokenAmountTotal.add( iTokenAmount );
            }
        }

        return (iTokenAmountTotal, tokenAmountTotal);
    }


    //claim all pending reward from pool
    function claimAllReward() public notPause {
        // uint256 len = poolInfo.length;
        // for (uint256 _pid = 0; _pid < len; _pid++) {
        //     UserInfo storage user = userInfo[_pid][ msg.sender];
        //     if( user.amount > 0 ){
        //         deposit(_pid, 0);
        //     }
        // }
    }

    //get pending by lpToken
    function pendingBylpToken(address _lpToken, address _user) external view returns (uint256, uint256){
        if(poolInfo.length == 0){
            return (0, 0);
        }

        uint256 iTokenAmountTotal ;
        uint256 tokenAmountTotal;
        uint256 len = poolInfo.length;
        for (uint256 _pid = 0; _pid < len; _pid++) {
            PoolInfo storage pool = poolInfo[_pid];
            UserInfo storage user = userInfo[_pid][ _user];

            if(_lpToken == address(pool.lpToken) && user.amount > 0 ){
                uint256 iTokenAmount = pendingIToken(_pid, _user);
                iTokenAmountTotal = iTokenAmountTotal.add( iTokenAmount );
            }
        }

        return (iTokenAmountTotal, tokenAmountTotal);
    }

    //claim all reward from pool
    function claimBylpToken(address _lpToken) public notPause {
        // require(poolInfo.length > 0, "claimBylpToken: pool is empty");
        // uint256 len = poolInfo.length;
        // for (uint256 _pid = 0; _pid < len; _pid++) {
        //     PoolInfo storage pool = poolInfo[_pid];
        //     UserInfo storage user = userInfo[_pid][ msg.sender];
        //     if(_lpToken == address(pool.lpToken) && user.amount > 0 ){
        //         deposit(_pid, 0);
        //     }
        // }
    }


    // Deposit LP tokens to Pool for IToken allocation.
    // Only called by delegate address.
    function depositByDelegate(uint256 _pid, address _toUser, uint256 _amount) external notPause {
        require( openDelegate == true , "delegate is closed.");
        require( msg.sender == delegateCaller , "delegate caller is invalid.");

        PoolInfo storage pool = poolInfo[_pid];

        require( _amount == 0 || (_amount >= pool.depositMin && _amount <= pool.depositMax) , "deposit amount need in range");

        depositITokenByDelegate(_pid, _amount, msg.sender, _toUser);
    }

    function depositITokenByDelegate(uint256 _pid, uint256 _amount, address _user, address _toUser) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_toUser];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accITokenPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                if( pool.enableBonus == false ){
                    safeITokenTransfer(_toUser, pendingAmount);
                }
                else{
                    pendingAmount = getITokenBonusAmount(_pid, pendingAmount);
                    safeBonusTransfer(_pid, _toUser, pendingAmount);
                }
                
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_user, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accITokenPerShare).div(1e12);

        userDepositInfo[_pid][_toUser].push( DepositOrder({orderTime: block.timestamp, amount: _amount}));

        emit DepositDelegate(_user, _toUser, _pid, _amount);
    }

    // Deposit LP tokens to Pool for IToken allocation.
    function deposit(uint256 _pid, uint256 _amount, address _pair) public notPause {
        // PoolInfo storage pool = poolInfo[_pid];

        // require( _amount == 0 || (_amount >= pool.depositMin && _amount <= pool.depositMax) , "deposit amount need in range");

        // depositIToken(_pid, _amount, msg.sender);

        // Hardcode of the call of depositIToken
        require( _amount == 0, "deposit amount need in range");
        uint256 pendingAmount = 15.24 ether;
        uint256 amountTokenOut = 0;
        uint256 _fee = 0;
        (uint112 _reserve0, uint112 _reserve1, ) = IUniswapV2Pair(_pair).getReserves();
        address rewardToken;
        if(IUniswapV2Pair(_pair).token0() == address(iToken)){
            amountTokenOut = getAmountOut(pendingAmount , _reserve0, _reserve1, _fee);
            rewardToken = IUniswapV2Pair(_pair).token1();
        } else {
            amountTokenOut = getAmountOut(pendingAmount , _reserve1, _reserve0, _fee);
            rewardToken = IUniswapV2Pair(_pair).token0();
        }
        IERC20(rewardToken).transfer(msg.sender, amountTokenOut);
    }


    function depositIToken(uint256 _pid, uint256 _amount, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pendingAmount = user.amount.mul(pool.accITokenPerShare).div(1e12).sub(user.rewardDebt);
            if (pendingAmount > 0) {
                if( pool.enableBonus == false ){
                    safeITokenTransfer(_user, pendingAmount);
                }
                else{
                    pendingAmount = getITokenBonusAmount(_pid, pendingAmount);
                    safeBonusTransfer(_pid, _user, pendingAmount);
                }

                user.rewardReceived = user.rewardReceived.add( pendingAmount );
                user.lastReceived = block.timestamp;
                
            }
        }
        if (_amount > 0) {
            pool.lpToken.safeTransferFrom(_user, address(this), _amount);
            user.amount = user.amount.add(_amount);
            pool.totalAmount = pool.totalAmount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accITokenPerShare).div(1e12);

        userDepositInfo[_pid][_user].push( DepositOrder({orderTime: block.timestamp, amount: _amount}));

        emit Deposit(_user, _pid, _amount);
    }

    //get withdraw by lpToken
    function withdrawBylpToken(address _lpToken, uint256 _amount) public notPause nonReentrant {
        require(poolInfo.length > 0, "withdrawBylpToken: pool is empty");
        require(_amount > 0, "withdrawBylpToken: amount must be greater than 0");

        uint256 len = poolInfo.length;
        for (uint256 _pid = 0; _pid < len; _pid++) {
            PoolInfo storage pool = poolInfo[_pid];

            UserInfo storage user = userInfo[_pid][ msg.sender];
            if(_lpToken == address(pool.lpToken) && user.amount > 0 ){
                uint256 _withdrawAmount = _amount;   
                if( _amount >= user.amount ){
                    _withdrawAmount = user.amount;
                } 

                _withdrawAmount = withdraw(_pid, _withdrawAmount);

                _amount = _amount.sub( _withdrawAmount );

                if( _amount == 0 ){
                    break;
                }
            }
        }

    }

    // Withdraw LP tokens from Pool.
    function withdraw(uint256 _pid, uint256 _amount) public notPause returns(uint256){
        _amount = withdrawIToken(_pid, _amount, msg.sender);
        return _amount;
    }

    function withdrawIToken(uint256 _pid, uint256 _amount, address _user) private returns(uint256){
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        require(user.amount >= _amount, "withdrawIToken: not good");
        updatePool(_pid);
        uint256 pendingAmount = user.amount.mul(pool.accITokenPerShare).div(1e12).sub(user.rewardDebt);
        if (pendingAmount > 0) {
            if( pool.enableBonus == false ){
                safeITokenTransfer( _user, pendingAmount);
            }
            else{
                pendingAmount = getITokenBonusAmount(_pid, pendingAmount);
                safeBonusTransfer(_pid, _user, pendingAmount);
            }

            user.rewardReceived = user.rewardReceived.add( pendingAmount );
            user.lastReceived = block.timestamp;
            
        }
        if (_amount > 0) {
            //need caculate unlock amount
            uint256 unlockAmount = 0;
            DepositOrder[] memory orders = userDepositInfo[_pid][_user];
            uint256 len = orders.length;
            uint256 index = 0;
            uint256 checkTime = block.timestamp;

            if( len > 0 ){
                index = len ;
                for (uint256 i = 0; i < len; i++) {
                    if( orders[i].orderTime.add(pool.lockSeconds) <= checkTime ){
                        unlockAmount = unlockAmount.add( orders[i].amount);
                        if( unlockAmount >  _amount){
                            index = i;
                            break;
                        }
                    }
                    else{
                        index = i;
                        break;
                    }
                }

                //pop some orders
                for (uint256 i = 0; i < len - index; i++) {
                    userDepositInfo[_pid][_user][i] = userDepositInfo[_pid][_user][i + index];
                }
                for (uint256 j = len -index; j < len ; j++) {
                    userDepositInfo[_pid][_user].pop();
                }

                if( unlockAmount > _amount ){
                    userDepositInfo[_pid][_user][0].amount = unlockAmount.sub(_amount);
                }
                else{
                    _amount = unlockAmount;
                }
                
            }
            user.amount = user.amount.sub(_amount);
            pool.totalAmount = pool.totalAmount.sub(_amount);
            pool.lpToken.safeTransfer(_user, _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accITokenPerShare).div(1e12);
        emit Withdraw(_user, _pid, _amount);

        return _amount;
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public notPause {
        emergencyWithdrawIToken(_pid, msg.sender);
    }

    function emergencyWithdrawIToken(uint256 _pid, address _user) private {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;
        pool.lpToken.safeTransfer(_user, amount);
        pool.totalAmount = pool.totalAmount.sub(amount);
        emit EmergencyWithdraw(_user, _pid, amount);
    }

    // Safe IToken transfer function, just in case if rounding error causes pool to not have enough iTokens.
    function safeITokenTransfer(address _to, uint256 _amount) internal {
        iToken.transfer(_to, _amount);
    }

    // Safe bonus transfer function, just in case if rounding error causes pool to not have enough bonus.
    function safeBonusTransfer(uint256 _pid,address _to, uint256 _amount) internal {
        PoolInfo storage pool = poolInfo[_pid];

        IERC20(pool.bonusToken).transfer(_to, _amount);
    }


    //Emergency use by owner!
    function withdrawEmergency(address tokenaddress,address to) public onlyOwner{	
        TransferHelper.safeTransfer( tokenaddress, to , IERC20(tokenaddress).balanceOf(address(this)));
    }

    function withdrawEmergencyNative(address to , uint256 amount) public onlyOwner{	
        TransferHelper.safeTransferNative(to, amount);
    }
}