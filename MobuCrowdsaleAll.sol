pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/c5d66183abcb63a90a2528b8333b2b17067629fc/contracts/math/SafeMath.sol
/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// ----------------------------------------------------------------------------
// Ownership functionality for authorization controls and user permissions
// ----------------------------------------------------------------------------

// https://github.com/OpenZeppelin/zeppelin-solidity/blob/c5d66183abcb63a90a2528b8333b2b17067629fc/contracts/ownership/Ownable.sol
/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**
 * @title TokenContract
 * @dev Simpler version of MobuToken
 */
contract TokenContract {
  function transfer(address to, uint256 value) public returns (bool);
  function setCrowdsaleContract (address _address) public;
  function balanceOf(address who) public view returns (uint256);
  function setIcoFinish(uint _date) public;
}


/**
 * @title MobuCrowdsale contract
 * @dev This contract includes preICO and ICO parts
 */
 contract MobuCrowdsale is Ownable {

  using SafeMath for uint;

  //constants
  uint public constant DECIMALS = 18;
  uint public constant PRE_ICO_MIN_INVEST = 1 ether;
  uint public constant ICO_MIN_INVEST = 0.1 ether;
  uint public constant tokenPrice = 15; //0.15 USD

  //events
  event OnSuccessfullyBought(address indexed contributor, uint indexed etherValue, bool indexed isManually, uint tokenValue);
  event OnRateChange(uint newRate);
  event Refund(address indexed contributor, uint etherValue);

  //global variables

  uint public preIcoStart = 0;//1535799600;
  uint public preIcoFinish = 1537009200;

  uint public icoStart = 1543662000;
  uint icoFinish = 1548892800;

  function getIcoFinish () public view returns(uint) {
    return icoFinish;
  }
  

  uint public icoMinCap; //ether
  uint public icoMaxCap; //ether

  uint public ethCollected = 0; //ether

  uint public currentRate; 

  //address => ether amount
  mapping (address => uint) public contributors;

  //start whiteList functionality
  mapping (address => bool) public whiteList;

  function addToWhiteList (address[] addresses) external onlyOwner {
    for (uint i = 0; i < addresses.length; i++){
      whiteList[addresses[i]] = true;
    }
  }

  function removeFromWhiteList (address[] addresses) external onlyOwner {
    for (uint i = 0; i < addresses.length; i++){
      whiteList[addresses[i]] = false;
    }
  }

  //end whiteList functionality

  function setPreIcoStage (uint _start, uint _finish) public onlyOwner {
    preIcoStart = _start;
    preIcoFinish = _finish;
  }

  function setIcoStage (uint _start, uint _finish) public onlyOwner {
    icoStart = _start;
    icoFinish = _finish;
    token.setIcoFinish(icoFinish);
  }
  
  //address which will contain all ICO ether
  address public distributionAddress;

  // Token contract address
  TokenContract public token;

  // Constructor
  constructor (address _tokenAddress, address _distributionAddress, uint _rate) public {
    token = TokenContract(_tokenAddress);
    
    currentRate = _rate;
    icoMinCap = 100000000 ether/currentRate;
    icoMaxCap = 3500000000 ether/currentRate;

    distributionAddress = _distributionAddress;

    token.setCrowdsaleContract(this);
    token.setIcoFinish(icoFinish);
  }

  /**
   * @dev fallback function, redirect to buy function
   */
  function () public payable {
    require (isActive(now));
    require (whiteList[msg.sender]);
    require (buy(msg.sender, msg.value, now));
  }

  /**
   * @dev private function to buy tokens
   */
  function buy (address _address, uint _value, uint _time) private returns (bool) {

    uint tokens = _value.mul(currentRate)/tokenPrice;

    require (ethCollected.add(_value) <= icoMaxCap);

    if (isPreIco(_time)){
      require (_value >= PRE_ICO_MIN_INVEST);
      forwardFunds();
    }else if (isIco(_time)){
      require (_value >= ICO_MIN_INVEST);
      
      contributors[_address] = contributors[_address].add(_value);

      if (ethCollected >= icoMinCap){
        forwardFunds();
      }
    }

    ethCollected = ethCollected.add(_value);

    token.transfer(_address, tokens);

    emit OnSuccessfullyBought(_address, _value, false, tokens);

    return true;
  }

  function sendEtherManually(address _address, uint _value, uint _bonus) public onlyOwner {
    uint tokens = _value.mul(currentRate)/tokenPrice;
    tokens = tokens.add(tokens.mul(_bonus)/100);

    require (ethCollected.add(_value) <= icoMaxCap);

    ethCollected = ethCollected.add(_value);
    token.transfer(_address, tokens);

    emit OnSuccessfullyBought(_address, _value, true, tokens);
  }
  

  /**
   * @param _time Timestamp in seconds
   * @dev returns true if now preICO or ICO stage
   */
  function isActive(uint _time) public view returns (bool){
    if (_time == 0){
      _time = now;
    }

    if ((preIcoStart < _time && _time <= preIcoFinish) ||
      icoStart < _time && _time <= icoFinish){
      return true;
    }

    return false;
  }

  /**
   * @param _time Timestamp in seconds
   * @dev returns true if now preICO stage
   */
  function isPreIco(uint _time) public view returns (bool){
    if (_time == 0){
      _time = now;
    }

    if (preIcoStart < _time && _time <= preIcoFinish){
      return true;
    }
    return false;
  }

  /**
   * @param _time Timestamp in seconds
   * @ dev returns true if now ICO stage
   */
  function isIco(uint _time) public view returns (bool){
    if (_time == 0){
      _time = now;
    }
    if (icoStart < _time && _time <= icoFinish){
      return true;
    }
    return false;
  }

  function forwardFunds() private {
    distributionAddress.transfer(address(this).balance);
  }

  /**
   * @param _rate new rate ETH/USD
   * @dev if ETH cost $534,43 input must be 53443
   */
  function setCurrentRate(uint _rate) public onlyOwner {
    currentRate = _rate;
    icoMinCap = uint(100000000 ether)/_rate;
    icoMaxCap = uint(3500000000 ether) /_rate;
    emit OnRateChange(_rate);
  }

  /**
   * @dev function to refund ether if ICO failed
   * Can be used only after ICO finish
   */
  function refund () public {
    require (now > icoFinish);
    require (ethCollected < icoMinCap);
    require (contributors[msg.sender] > 0);

    uint buffer = contributors[msg.sender];
    contributors[msg.sender] = 0;
    msg.sender.transfer(buffer);

    emit Refund(msg.sender, buffer);
  }

  /**
   * @dev Function to return all remaining tokens from this contract
   * to current contract owner.
   */
  function returnTokens () public onlyOwner {
    require (now > icoFinish);

    uint _tokens = token.balanceOf(address(this));
    token.transfer(owner, _tokens);
  }
}