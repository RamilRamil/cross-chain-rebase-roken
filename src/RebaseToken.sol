// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

using SafeERC20 for ERC20;

/**
* @title RebaseToken
* @author Ramil Mustafin
*/

contract RebaseToken is ERC20, Ownable, AccessControl{
    error RebaseToken_InterestRateCanOnlyDecrease(uint256, uint256);

    uint256 private constant PRECISION_FACTOR = 1e18;
    bytes32 private constant MINT_AND_BURN_ROLE = keccak256("MINT_AND_BURN_ROLE");
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_lastTimeUpdated;

    event InterestRateUpdate(uint256);

    constructor(address initialOwner) ERC20('Rebase Token', 'RBT') Ownable(initialOwner) {}

    /**
    * @notice Grant the mint and burn role to the specified address
    * @param _user The address to grant the mint and burn role to
    */
    function grantMintAndBurnRole(address _user) external onlyOwner {
        _grantRole(MINT_AND_BURN_ROLE, _user);
    }

    /**
    * @notice Set the interest rate
    * @param _newInterestRate The new interest rate
    */
    function setInterestRate(uint256 _newInterestRate) external onlyOwner{
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken_InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateUpdate(_newInterestRate);
    }

    /**
    * @notice Get the principle balance of the specified address, not including the interest earned from the last update
    * @param _user The address to get the principle balance of
    * @return The principle balance of the specified address
    */
    function principleBalanceOf(address _user) external view returns(uint256) {
        return super.balanceOf(_user);
    }

    /**
    * @notice Get the interest rate 
    * @return The interest rate
    */
    function getInterestRate() external view returns(uint256) {
        return s_interestRate;
    }

    /**
    * @notice Mint tokens to the specified address
    * @param _to The address to mint tokens to
    * @param _amount The amount of tokens to mint
    */
    function mint(address _to, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        _mintAccuredInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    /**
    * @notice Burn tokens from the specified address
    * @param _from The address to burn tokens from
    * @param _amount The amount of tokens to burn
    */
    function burn(address _from, uint256 _amount) external onlyRole(MINT_AND_BURN_ROLE) {
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        _mintAccuredInterest(_from);
        _burn(_from, _amount);
    }

    /**
    * @notice Get the balance of the specified address
    * @param _user The address to get the balance of
    * @return The balance of the specified address
    */
    function balanceOf(address _user) public view override returns (uint256) {
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceUpdate(_user) / PRECISION_FACTOR;
    }

    /**
    * @notice Transfer tokens from the specified address
    * @param _to The address to transfer tokens to
    * @param _amount The amount of tokens to transfer
    * @return True if the transfer was successful
    */
    function transfer(address _to, uint256 _amount) public override returns (bool) {
        _mintAccuredInterest(msg.sender);
        _mintAccuredInterest(_to);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(msg.sender);
        }
        if (balanceOf(_to) == 0) {
            s_userInterestRate[_to] = s_userInterestRate[msg.sender];
            s_lastTimeUpdated[_to] = block.timestamp;
        }
        return super.transfer(_to, _amount);
    }

    /**
    * @notice Transfer tokens from the specified address
    * @param _from The address to transfer tokens from
    * @param _to The address to transfer tokens to
    * @param _amount The amount of tokens to transfer
    * @return True if the transfer was successful
    */
    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        _mintAccuredInterest(_from);
        _mintAccuredInterest(_to);
        if (_amount == type(uint256).max) {
            _amount = balanceOf(_from);
        }
        if (balanceOf(_to) == 0) {
            s_userInterestRate[_to] = s_userInterestRate[_from];
            s_lastTimeUpdated[_to] = block.timestamp;
        }
        return super.transferFrom(_from, _to, _amount);
    }

    /**
    * @notice Mint tokens to the specified address
    * @param _user The address to mint tokens to
    */
    function _mintAccuredInterest(address _user) internal {
        // principle balance
        uint256 previousBalance = super.balanceOf(_user);
        uint256 currentBalance = balanceOf(_user);
        uint256 interest = currentBalance - previousBalance;
        s_lastTimeUpdated[_user] = block.timestamp;
        _mint(_user, interest);
    }

    /**
    * @notice Get the interest rate of the specified address
    * @param _user The address to get the interest rate of
    * @return The interest rate of the specified address
    */
    function getUserInterestRate(address _user) external returns(uint256) {
        return s_userInterestRate[_user];
    }

    /**
    * @notice Calculate the accumulated interest since the last update
    * @param _user The address to calculate the accumulated interest for
    * @return linearInterestRate The accumulated interest since the last update
    */
    function _calculateUserAccumulatedInterestSinceUpdate(address _user) internal view returns(uint256 linearInterestRate) {
        uint256 timeFromLastUpdate = block.timestamp - s_lastTimeUpdated[_user];
        linearInterestRate = PRECISION_FACTOR + (s_userInterestRate[_user] * timeFromLastUpdate);
    }

}