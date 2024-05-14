import { time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';


describe("CeritficateToken", function () {

  describe("test mint", function () {
    it("Init contract", async function () {
      const [owner, recipient] = await ethers.getSigners();
      const tokenFactory = await ethers.getContractFactory("CertificateToken");
      let token = await tokenFactory.deploy('CertificateToken', 'CT', 18, await owner.getAddress());
      token = await token.waitForDeployment();
      const amount = BigInt(100);
      await token.mint(await recipient.getAddress(), amount);
      expect(await token.balanceOf(await recipient.getAddress())).to.equal(amount);
    });
  });
  describe("test burn", function () {
    it("Init contract", async function () {
      const [owner, recipient] = await ethers.getSigners();
      const tokenFactory = await ethers.getContractFactory("CertificateToken");
      let token = await tokenFactory.deploy('CertificateToken', 'CT', 18, await owner.getAddress());
      token = await token.waitForDeployment();
      const amount = BigInt(100);
      await token.mint(await recipient.getAddress(), amount);
      await token.burnFrom(await recipient.getAddress(), amount);
      expect(await token.balanceOf(await recipient.getAddress())).to.equal(0);
    });
  });

  describe("test role based access control", function () {
    it("Init contract", async function () {
      const [owner, recipient] = await ethers.getSigners();
      const tokenFactory = await ethers.getContractFactory("CertificateToken");
      let token = await tokenFactory.deploy('CertificateToken', 'CT', 18, await owner.getAddress());
      token = await token.waitForDeployment();
      const amount = BigInt(100);
      await token.mint(await recipient.getAddress(), amount);
      await expect(token.connect(recipient).mint(await recipient.getAddress(), amount)).to.be.reverted;
      await token.burnFrom(await recipient.getAddress(), amount);
      await expect(token.connect(recipient).burnFrom(await recipient.getAddress(), amount)).to.be.reverted;
      expect(await token.balanceOf(await recipient.getAddress())).to.equal(0);
    });
  });
});
