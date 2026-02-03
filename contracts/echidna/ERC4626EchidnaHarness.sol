// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC4626Vault} from "../ERC4626Vault.sol";
import {MintableERC20} from "../test/MintableERC20.sol";

/**
 * @notice Echidna harness for ERC4626Vault.
 * Echidna calls public functions and expects invariant functions returning bool.
 *
 * We mint tokens to this harness, approve the vault, and let Echidna explore sequences
 * of deposits/mints/withdraws/redeems.
 */
contract ERC4626EchidnaHarness {
    MintableERC20 public token;
    ERC4626Vault public vault;

    constructor() {
        token = new MintableERC20("Mock USD", "mUSD", 18);
        vault = new ERC4626Vault(token, "Share Vault", "sVLT");

        token.mint(address(this), 1_000_000 ether);
        token.approve(address(vault), type(uint256).max);
    }

    // ---------- Actions ----------
    function act_deposit(uint256 assets) public {
        assets = assets % (10_000 ether);
        if (assets == 0) return;
        vault.deposit(assets, address(this));
    }

    function act_mint(uint256 shares) public {
        shares = shares % (10_000 ether);
        if (shares == 0) return;
        // mint will pull the required assets from this harness
        // ensure we have enough underlying by bounding required assets
        uint256 required = vault.previewMint(shares);
        if (required == 0 || required > token.balanceOf(address(this))) return;
        vault.mint(shares, address(this));
    }

    function act_withdraw(uint256 assets) public {
        assets = assets % (10_000 ether);
        if (assets == 0) return;

        // if vault doesn't have enough shares to cover, withdraw will revert
        // so we bound by maxWithdraw
        uint256 maxW = vault.maxWithdraw(address(this));
        if (assets > maxW) assets = maxW;
        if (assets == 0) return;

        vault.withdraw(assets, address(this), address(this));
    }

    function act_redeem(uint256 shares) public {
        shares = shares % (10_000 ether);
        if (shares == 0) return;

        uint256 maxR = vault.maxRedeem(address(this));
        if (shares > maxR) shares = maxR;
        if (shares == 0) return;

        vault.redeem(shares, address(this), address(this));
    }

    // ---------- Invariants ----------
    // Vault totalAssets should equal underlying token balance held by vault (this vault does not invest elsewhere)
    function echidna_totalAssets_matches_balance() public view returns (bool) {
        return vault.totalAssets() == token.balanceOf(address(vault));
    }

    // "No free lunch": if you redeem all your shares, you shouldn't get more assets than vault holds.
    function echidna_redeem_all_not_exceed_totalAssets() public view returns (bool) {
        uint256 s = vault.balanceOf(address(this));
        uint256 a = vault.previewRedeem(s);
        return a <= vault.totalAssets();
    }
}
