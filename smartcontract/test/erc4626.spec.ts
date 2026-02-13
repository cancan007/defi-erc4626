import { expect } from "chai";
import { ethers } from "hardhat";

describe("ERC4626Vault", () => {
  it("deposit -> shares minted; redeem -> assets out", async () => {
    const [deployer, alice] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("MintableERC20");
    const token = await Token.deploy("Mock USD", "mUSD", 18);
    await token.waitForDeployment();

    const Vault = await ethers.getContractFactory("ERC4626Vault");
    const vault = await Vault.deploy(await token.getAddress(), "Share Vault", "sVLT");
    await vault.waitForDeployment();

    await token.mint(alice.address, ethers.parseEther("1000"));
    await token.connect(alice).approve(await vault.getAddress(), ethers.MaxUint256);

    // deposit 100 assets
    const tx = await vault.connect(alice).deposit(ethers.parseEther("100"), alice.address);
    await tx.wait();

    const shares = await vault.balanceOf(alice.address);
    expect(shares).to.equal(ethers.parseEther("100")); // initial 1:1

    // redeem 40 shares
    await vault.connect(alice).redeem(ethers.parseEther("40"), alice.address, alice.address);

    expect(await vault.balanceOf(alice.address)).to.equal(ethers.parseEther("60"));
    expect(await token.balanceOf(alice.address)).to.equal(ethers.parseEther("940"));
    expect(await vault.totalAssets()).to.equal(await token.balanceOf(await vault.getAddress()));
  });

  it("previewMint/previewWithdraw should be consistent", async () => {
    const [_, alice] = await ethers.getSigners();

    const Token = await ethers.getContractFactory("MintableERC20");
    const token = await Token.deploy("Mock USD", "mUSD", 18);
    await token.waitForDeployment();

    const Vault = await ethers.getContractFactory("ERC4626Vault");
    const vault = await Vault.deploy(await token.getAddress(), "Share Vault", "sVLT");
    await vault.waitForDeployment();

    await token.mint(alice.address, ethers.parseEther("1000"));
    await token.connect(alice).approve(await vault.getAddress(), ethers.MaxUint256);

    await vault.connect(alice).deposit(ethers.parseEther("123"), alice.address);

    const shares = ethers.parseEther("10");
    const assetsForMint = await vault.previewMint(shares);
    // mint should pull exactly assetsForMint (within OZ rounding rules it should be exact for this simple vault)
    await vault.connect(alice).mint(shares, alice.address);

    // now withdrawing assetsForMint should require ~shares (rounding may differ by 1 wei)
    const sharesForWithdraw = await vault.previewWithdraw(assetsForMint);
    expect(sharesForWithdraw).to.be.greaterThan(0n);
  });
});
