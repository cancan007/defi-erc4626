// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";

/**
 * @title ERC4626Vault
 * @notice Standard ERC-4626 vault based on OpenZeppelin v5 implementation.
 *
 * Security:
 * - nonReentrant wrappers on deposit/mint/withdraw/redeem
 * - OZ ERC4626 handles share/asset math with well-tested patterns
 *
 * Notes:
 * - This vault does NOT invest into external protocols; totalAssets == asset balance.
 * - It's a clean baseline for DeFi vault patterns and for security tooling / invariants.
 */
contract ERC4626Vault is ERC4626, ReentrancyGuard, Ownable2Step {
    constructor(
        IERC20 asset_,
        string memory shareName,
        string memory shareSymbol
    ) ERC20(shareName, shareSymbol) ERC4626(asset_) Ownable(msg.sender) {
        _transferOwnership(msg.sender);
    }

    // ---- Reentrancy-safe entrypoints (wrap OZ logic) ----

    function deposit(
        uint256 assets,
        address receiver
    ) public override nonReentrant returns (uint256) {
        return super.deposit(assets, receiver);
    }

    function mint(
        uint256 shares,
        address receiver
    ) public override nonReentrant returns (uint256) {
        return super.mint(shares, receiver);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256) {
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public override nonReentrant returns (uint256) {
        return super.redeem(shares, receiver, owner);
    }

    // Optional safety: allow owner to rescue unrelated tokens sent by mistake (not the vault asset)
    function rescueToken(
        IERC20 token,
        address to,
        uint256 amount
    ) external onlyOwner {
        require(address(token) != address(asset()), "cannot rescue asset");
        require(to != address(0), "zero addr");
        token.transfer(to, amount);
    }
}
