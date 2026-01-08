//SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { Test, console } from "forge-std/Test.sol";
import { RebaseToken } from "../src/RebaseToken.sol";
import { Vault } from "../src/Vault.sol";
import { IRebaseToken } from "../src/interfaces/IRebaseToken.sol";

contract RebaseTokenTest is Test {
    RebaseToken private rebaseToken;
    Vault private vault;

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() public {
        vm.startPrank(owner);
        rebaseToken = new RebaseToken(owner);
        vault = new Vault(IRebaseToken(address(rebaseToken)));
        rebaseToken.grantMintAndBurnRole(address(vault));
        payable(address(vault)).call{value: 1 ether}("");
        vm.stopPrank();
    }

    function testDeposit() public {
        vm.prank(user);
        vm.deal(user, 1 ether);
        vault.deposit{value: 1 ether}();
        assertEq(rebaseToken.balanceOf(user), 1 ether);
    }

    function testWithdraw() public {
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        vault.deposit{value: 1 ether}();
        vault.withdraw(1 ether);
        vm.stopPrank();
        assertEq(rebaseToken.balanceOf(user), 0);
    }
}