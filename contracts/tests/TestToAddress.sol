pragma solidity ^0.4.23;

import "../ToAddress.sol";


contract TestToAddress {
  using ToAddress for *;
  
  function toAddress(bytes source) public pure returns(address addr) {
    return source.toAddress();
  }

  function isNotContract(address addr) public view returns(bool) {
    return addr.isNotContract();
  }
}
