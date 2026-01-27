//SPDX-License-Identifier: MIT
pragma solidity 0.8.33;

import { RebaseToken } from "../../src/RebaseToken.sol";
import { RebaseTokenPool } from "../../src/RebaseTokenPool.sol";
import { Vault } from "../../src/Vault.sol";
import { CCIPLocalSimulatorFork, Register } from "@chainlink-local/src/ccip/CCIPLocalSimulatorFork.sol";
import { Test } from "forge-std/Test.sol";
import { IRebaseToken } from "../../src/interfaces/IRebaseToken.sol";
import { IERC20 } from "@chainlink-local/src/ccip/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/IERC20.sol";
import { RegistryModuleOwnerCustom } from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/RegistryModuleOwnerCustom.sol";
import { TokenAdminRegistry } from "@ccip/contracts/src/v0.8/ccip/tokenAdminRegistry/TokenAdminRegistry.sol";

contract CrossChainTest is Test {
    address owner = makeAddr("owner");
    uint256 sepoliaFork;
    uint256 arbSepoliaFork;

    CCIPLocalSimulatorFork ccipLocalSimulatorFork;

    RebaseToken sepoliaToken;
    RebaseToken arbSepoliaToken;

    RebaseTokenPool sepoliaTokenPool;
    RebaseTokenPool arbSepoliaTokenPool;

    Register.NetworkDetails sepoliaNetworkDetails;
    Register.NetworkDetails arbSepoliaNetworkDetails;

    Vault vault;

    function setUp() public {
        sepoliaFork = vm.createSelectFork("sepolia-eth");
        arbSepoliaFork = vm.createSelectFork("arb-sepolia");

        ccipLocalSimulatorFork = new CCIPLocalSimulatorFork();
        vm.makePersistent(address(ccipLocalSimulatorFork));

        // 1. Deploy on sepolia
        sepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainId);
        vm.selectFork(sepoliaFork);
        vm.startPrank(owner);
        sepoliaToken = new RebaseToken(owner);
        vault = new Vault(IRebaseToken(address(sepoliaToken)));
        sepoliaTokenPool = new RebaseTokenPool(
            IERC20(address(sepoliaToken)), 
            new address[](0),
            sepoliaNetworkDetails.rmnProxy, 
            sepoliaNetworkDetails.routerAddress);
        sepoliaToken.grantMintAndBurnRole(address(vault));
        sepoliaToken.grantMintAndBurnRole(address(sepoliaTokenPool));
        RegistryModuleOwnerCustom(sepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(sepoliaToken));
        TokenAdminRegistry(sepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(sepoliaToken), address(sepoliaTokenPool));
        vm.stopPrank();

        // 2. Deploy on arb-sepolia
        vm.selectFork(arbSepoliaFork);
        arbSepoliaNetworkDetails = ccipLocalSimulatorFork.getNetworkDetails(block.chainId);
        vm.startPrank(owner);
        arbSepoliaToken = new RebaseToken(address(owner));
        arbSepoliaTokenPool = new RebaseTokenPool(
            IERC20(address(arbSepoliaToken)), 
            new address[](0),
            arbSepoliaNetworkDetails.rmnProxy, 
            arbSepoliaNetworkDetails.routerAddress);
        arbSepoliaToken.grantMintAndBurnRole(address(arbSepoliaTokenPool));
        RegistryModuleOwnerCustom(arbSepoliaNetworkDetails.registryModuleOwnerCustomAddress).registerAdminViaOwner(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).acceptAdminRole(address(arbSepoliaToken));
        TokenAdminRegistry(arbSepoliaNetworkDetails.tokenAdminRegistryAddress).setPool(address(arbSepoliaToken), address(arbSepoliaTokenPool));
        vm.stopPrank();
    }
}