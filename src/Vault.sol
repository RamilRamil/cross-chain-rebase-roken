//SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IRebaseToken } from "./interfaces/IRebaseToken.sol";

contract Vault is Ownable {
    IRebaseToken private immutable i_rebaseToken;

    error Vault_WithdrawFailed();
    error Vault_WithdrawAmountExceedsBalance();
    error Vault_DepositAmountIsZero();

    event Deposit(address indexed _user, uint256 _amount);
    event Redeem(address indexed _user, uint256 _amount);

    constructor(IRebaseToken _rebaseToken) Ownable(msg.sender) {
        i_rebaseToken = _rebaseToken;
    }

    receive() external payable {}

    function deposit() external payable {
        if (msg.value == 0) {
            revert Vault_DepositAmountIsZero();
        }
        i_rebaseToken.mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 _amount) external {
        if (_amount == type(uint256).max) {
            _amount = i_rebaseToken.balanceOf(msg.sender);
        }
        if (_amount > i_rebaseToken.balanceOf(msg.sender)) {
            revert Vault_WithdrawAmountExceedsBalance();
        }
        i_rebaseToken.burn(msg.sender, _amount);
        (bool success, ) = payable(msg.sender).call{value: _amount}("");
        if (!success) {
            revert Vault_WithdrawFailed();
        }
        emit Redeem(msg.sender, _amount);
    }

    function getRebaseTokenAddress() external view returns (address) {
        return address(i_rebaseToken);
    }
}