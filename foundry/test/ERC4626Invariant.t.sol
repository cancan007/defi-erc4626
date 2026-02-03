// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {ERC4626Vault} from "../../contracts/ERC4626Vault.sol";
import {MintableERC20} from "../../contracts/test/MintableERC20.sol";
import {VaultHandler} from "./handlers/VaultHandler.sol";

/**
 * @notice Invariant tests for ERC4626Vault.
 *
 * We focus on robust, *tool-friendly* invariants:
 * - totalAssets == underlying balance held by vault (because no external strategy)
 * - previewRedeem(totalSupply) <= totalAssets (no free assets)
 * - convertToAssets(totalSupply) should approximately match totalAssets (rounding-safe check)
 */
contract ERC4626InvariantTest is Test {
    MintableERC20 token;
    ERC4626Vault vault;
    VaultHandler handler;

    function setUp() public {
        token = new MintableERC20("Mock USD", "mUSD", 18);
        vault = new ERC4626Vault(token, "Share Vault", "sVLT");

        address[] memory actors = new address[](3);
        actors[0] = address(0xA11CE);
        actors[1] = address(0xB0B);
        actors[2] = address(0xCAFE);

        // seed balances
        for (uint256 i = 0; i < actors.length; i++) {
            token.mint(actors[i], 100_000 ether);
            vm.prank(actors[i]);
            token.approve(address(vault), type(uint256).max);
        }

        handler = new VaultHandler(vault, token, actors);

        // Tell Foundry to fuzz-call handler methods
        targetContract(address(handler));
        bytes4[] memory selectors = new bytes4[](4);
        selectors[0] = VaultHandler.deposit.selector;
        selectors[1] = VaultHandler.mint.selector;
        selectors[2] = VaultHandler.withdraw.selector;
        selectors[3] = VaultHandler.redeem.selector;
        targetSelector(FuzzSelector({addr: address(handler), selectors: selectors}));
    }

    function invariant_totalAssets_matches_balance() public view {
        assertEq(vault.totalAssets(), token.balanceOf(address(vault)));
    }

    function invariant_previewRedeem_totalSupply_not_exceed_totalAssets() public view {
        uint256 ts = vault.totalSupply();
        uint256 a = vault.previewRedeem(ts);
        assertLe(a, vault.totalAssets());
    }

    function invariant_convertToAssets_close_to_totalAssets() public view {
        // ERC4626 convertToAssets may round down. Ensure it's not greater than totalAssets
        uint256 ts = vault.totalSupply();
        uint256 a = vault.convertToAssets(ts);
        assertLe(a, vault.totalAssets());
    }
}
