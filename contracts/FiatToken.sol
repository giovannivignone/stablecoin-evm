pragma solidity ^0.4.18;

import './../lib/openzeppelin/contracts/token/ERC20/ERC20.sol';
import './../lib/openzeppelin/contracts/ownership/Ownable.sol';
import './../lib/openzeppelin/contracts/math/SafeMath.sol';

import './MintableTokenByRole.sol';
import './PausableTokenByRole.sol';
import './RedeemableToken.sol';
import './BlacklistableTokenByRole.sol';
import './EternalStorageUpdater.sol';

/**
 * @title FiatToken 
 * @dev ERC20 Token backed by fiat reserves
 */
contract FiatToken is ERC20, MintableTokenByRole, PausableTokenByRole, RedeemableToken, BlacklistableTokenByRole, Ownable {
  using SafeMath for uint256;

  string public name;
  string public symbol;
  string public currency;
  uint8 public decimals;

  function FiatToken(address _storageContractAddress, string _name, string _symbol, string _currency, uint8 _decimals, address _minter, address _pauser, address _accountCertifier, address _blacklister, address _reserver, address _minterCertifier) public {

    name = _name;
    symbol = _symbol;
    currency = _currency;
    decimals = _decimals;
    minter = _minter;
    pauser = _pauser;
    accountCertifier = _accountCertifier;
    reserver = _reserver;
    blacklister = _blacklister;
    minterCertifier = _minterCertifier;

    contractStorage = EternalStorage(_storageContractAddress);
  }

  /**
   * @dev Adds pausable condition to mint.
   * @return True if the operation was successful.
  */
  function mint(uint256 _amount) whenNotPaused public returns (bool) {
    return super.mint(_amount);
  }

  /**
   * @dev Adds pausable condition to finishMinting.
   * @return True if the operation was successful.
  */
  function finishMinting() whenNotPaused public returns (bool) {
    return super.finishMinting();
  }

  /**
   * @dev Get allowed amount for an account
   * @param owner address The account owner
   * @param spender address The account spender
  */
  function allowance(address owner, address spender) public view returns (uint256) {
    return getAllowed(owner, spender);
  }

  /**
   * @dev Get totalSupply of token
  */
  function totalSupply() public view returns (uint256) {
    return getTotalSupply();
  }

  /**
   * @dev Get token balance of an account
   * @param account address The account
  */
  function balanceOf(address account) public view returns (uint256) {
    return getBalance(account);
  }

  /**
   * @dev Adds blacklisted check to approve
   * @return True if the operation was successful.
  */
  function approve(address _spender, uint256 _value) whenNotPaused notBlacklisted public returns (bool) {
    require(isBlacklisted(_spender) == false);
    setAllowed(msg.sender, _spender, _value);
    Approval(msg.sender, _spender, _value);
  }

  /**
   * @dev Transfer tokens from one address to another.
   * Validates that the totalAmount <= the allowed amount for the sender on the from account.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   * @return bool success
  */
  function transferFrom(address _from, address _to, uint256 _value) whenNotPaused notBlacklisted public returns (bool) {
    require(isBlacklisted(_from) == false);
    require(isBlacklisted(_to) == false);

    uint256 allowed;
    allowed = getAllowed(_from, msg.sender);

    require(_value <= allowed);

    doTransfer(_from, _to, _value);
    setAllowed(_from, msg.sender, allowed.sub(_value));
    return true;
  }

  /**
   * @dev transfer token for a specified address
   * @param _to The address to transfer to.
   * @param _value The amount to be transferred.
   * @return bool success
  */
  function transfer(address _to, uint256 _value) whenNotPaused notBlacklisted public returns (bool) {
    require(isBlacklisted(_to) == false);

    doTransfer(msg.sender, _to, _value);
    return true;
  }

  /**
   * @dev updates balances for sender, recipient.
   * Validates that _to address exists, totalAmount <= balance of the from account.
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
  */
  function doTransfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    uint256 balance = getBalance(_from);

    require(_value <= balance);

    // SafeMath.sub will throw if there is not enough balance.
    setBalance(_from, balance.sub(_value));
    setBalance(_to, getBalance(_to).add(_value));
    Transfer(_from, _to, _value);
  }

}
