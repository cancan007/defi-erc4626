// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC4626Vault} from "../../../contracts/ERC4626Vault.sol";
import {MintableERC20} from "../../../contracts/test/MintableERC20.sol";

/**
 * @notice Handler used by Foundry invariant tests.
 * It defines stateful actions that Foundry will call in random sequences.
 */
contract VaultHandler is Test {
    ERC4626Vault public vault;
    MintableERC20 public token;

    address[] public actors;

    constructor(ERC4626Vault v, MintableERC20 t, address[] memory _actors) {
        vault = v;
        token = t;
        actors = _actors;
        for (uint256 i = 0; i < actors.length; i++) {
            vm.prank(actors[i]);
            token.approve(address(vault), type(uint256).max);
        }
    }

    function _actor(uint256 seed) internal view returns (address) {
        return actors[seed % actors.length];
    }

    function deposit(uint256 actorSeed, uint256 assets) external {
        address a = _actor(actorSeed);
        assets = bound(assets, 1e6, 10_000 ether); // avoid dust that rounds to 0 in previews

        // ensure actor has assets
        if (token.balanceOf(a) < assets) {
            token.mint(a, assets);
        }

        vm.prank(a);
        vault.deposit(assets, a);
    }

    function mint(uint256 actorSeed, uint256 shares) external {
        address a = _actor(actorSeed);
        shares = bound(shares, 1e6, 10_000 ether);

        uint256 req = vault.previewMint(shares);
        if (req == 0) return;

        if (token.balanceOf(a) < req) {
            token.mint(a, req);
        }

        vm.prank(a);
        vault.mint(shares, a);
    }

    function withdraw(uint256 actorSeed, uint256 assets) external {
        address a = _actor(actorSeed);
        uint256 maxW = vault.maxWithdraw(a);
        if (maxW == 0) return;

        assets = bound(assets, 1, maxW);
        vm.prank(a);
        vault.withdraw(assets, a, a);
    }

    function redeem(uint256 actorSeed, uint256 shares) external {
        address a = _actor(actorSeed);
        uint256 maxR = vault.maxRedeem(a);
        if (maxR == 0) return;

        shares = bound(shares, 1, maxR);
        vm.prank(a);
        vault.redeem(shares, a, a);
    }
}
