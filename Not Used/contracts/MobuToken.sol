pragma solidity ^0.4.24;

import 'zeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol';
import "zeppelin-solidity/contracts/ownership/Ownable.sol";

contract MobuToken is StandardBurnableToken, Ownable {

  event TeamTokensReleased();

  using SafeMath for uint256;

  string public symbol = "MOBU";
  string public name = "MOBU";
  uint256 public decimals = 18;

  address public tokenHolder;
  address public teamWallet;
  address public bountyWallet;


  constructor (address _tokenHolder) public {
    totalSupply_ = 350000000 ether;

    uint teamBalance = totalSupply_.mul(12)/100;
    uint bountyBalance = totalSupply_.mul(8)/100;

    tokenHolder = _tokenHolder;

    teamWallet = 0xF637Ba8Fe861AaeF1b9F8B45b9e0B040aF15e018;
    bountyWallet = 0xD5778CB3844b530eAf9F115aF9F295e378A1b449;

    balances[teamWallet] = teamBalance;
    balances[bountyWallet] = bountyBalance;

    balances[tokenHolder] = totalSupply_.sub(teamBalance).sub(bountyBalance);

    creationTimestamp = now;


    emit Transfer(address(0), teamWallet, teamBalance);
    emit Transfer(address(0), bountyWallet, bountyBalance);
    emit Transfer(address(0), tokenHolder, balances[tokenHolder]);

  }

  uint public creationTimestamp;

  address public crowdsale;

  function setCrowdsaleContract (address _address) public {
    require (crowdsale == address(0));

    crowdsale = _address;
  }
  
  uint public icoFinish;

  function setIcoFinish(uint _date) public {
    require (msg.sender == crowdsale);
    icoFinish = _date;
  }

  /**
   * @dev Rewritten function Transfer
   */
  function transfer(address _to, uint256 _value) public returns (bool) {
    if (msg.sender == bountyWallet) {
      super.transfer(_to, _value);
      return true;
    }
    require (now > icoFinish || msg.sender == owner || msg.sender == crowdsale);
    
    if (msg.sender == teamWallet){
      require (now > creationTimestamp + 31556926); //1 year
    }
    super.transfer(_to, _value);
  }

  /**
   * @dev Rewritten function TransferFrom
   */  
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    if (_from == bountyWallet) {
      super.transferFrom(_from, _to, _value);
      return true;
    }
    require (now > icoFinish || msg.sender == owner || msg.sender == crowdsale);

    if (_from == teamWallet){
      require (now > creationTimestamp + 31556926); //1 year
    }
    super.transferFrom(_from, _to, _value);
  }
}