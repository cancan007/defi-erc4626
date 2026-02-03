// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC4626Vault} from "../../contracts/ERC4626Vault.sol";
import {MintableERC20} from "../../contracts/test/MintableERC20.sol";

contract ERC4626FuzzTest is Test {
    MintableERC20 token;
    ERC4626Vault vault;
    address alice = address(0xA11CE);

    function setUp() public {
        token = new MintableERC20("Mock USD", "mUSD", 18);
        vault = new ERC4626Vault(token, "Share Vault", "sVLT");

        token.mint(alice, 1_000_000 ether);
        vm.prank(alice);
        token.approve(address(vault), type(uint256).max);
    }

    function testFuzz_deposit_redeem_roundtrip(uint256 assets) public {
        assets = bound(assets, 1e6, 10_000 ether);

        vm.startPrank(alice);
        uint256 shares = vault.deposit(assets, alice);

        // redeem some portion
        uint256 part = shares / 2;
        if (part > 0) {
            uint256 out = vault.redeem(part, alice, alice);
            assertGt(out, 0);
        }

        // accounting invariant for this vault
        assertEq(vault.totalAssets(), token.balanceOf(address(vault)));
        vm.stopPrank();
    }
}
