// SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

using SafeERC20 for ERC20;

/* 
* @title RebaseToken
* @author Ramil Mustafin
*/

contract RebaseToken is ERC20, Ownable{
    error RebaseToken_InterestRateCanOnlyDecrease(uint256, uint256);

    uint256 private constant PRECISION_FACTOR = 1e18;
    uint256 private s_interestRate = 5e10;
    mapping(address => uint256) private s_userInterestRate;
    mapping(address => uint256) private s_lastTimeUpdated;

    event InterestRateUpdate(uint256);

    constructor(address initialOwner) ERC20('Rebase Token', 'RBT') Ownable(initialOwner) {}

    function setInterestRate(uint256 _newInterestRate) external onlyOwner{
        if (_newInterestRate > s_interestRate) {
            revert RebaseToken_InterestRateCanOnlyDecrease(s_interestRate, _newInterestRate);
        }
        s_interestRate = _newInterestRate;
        emit InterestRateUpdate(_newInterestRate);
    }

    function mint(address _to, uint256 _amount) external onlyOwner {
        _mintAccuredInterest(_to);
        s_userInterestRate[_to] = s_interestRate;
        _mint(_to, _amount);
    }

    function balanceOf(address _user) public view override returns (uint256) {
        return super.balanceOf(_user) * _calculateUserAccumulatedInterestSinceUpdate(_user) / PRECISION_FACTOR;
    }

    function _mintAccuredInterest(address _user) internal {

    }

    function getUserInterestRate(address _user) external returns(uint256) {
        return s_userInterestRate[_user];
    }

    function _calculateUserAccumulatedInterestSinceUpdate(address _user) internal view returns(uint256 linearInterestRate) {
        uint256 timeFromLastUpdate = block.timestamp - s_lastTimeUpdated[_user];
        linearInterestRate = PRECISION_FACTOR + (s_userInterestRate[_user] * timeFromLastUpdate);

    }

}