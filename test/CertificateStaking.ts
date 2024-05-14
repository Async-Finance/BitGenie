import { time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';


describe("CeritficateStaking", function () {

  async function stake() {
    const [owner] = await ethers.getSigners();
    const EMPToken = await ethers.getContractFactory("EMP");
    let EMP = await EMPToken.deploy(1000000000);
    EMP = await EMP.waitForDeployment();
    const decimals = await EMP.decimals();
    const stakingContract = await ethers.getContractFactory("CertificateStaking");
    let staking = await stakingContract.deploy(await EMP.getAddress(), 'PEMP Token', 'PEMP');
    staking = await staking.waitForDeployment();
    let round = BigInt(0);
    let limit = BigInt(BigInt(20) * BigInt(10) ** decimals);
    let startTime = await time.latest() + 1000;

    const depositAmount = BigInt(BigInt(100000000) * BigInt(10) ** decimals);

    await EMP.approve(await staking.getAddress(), depositAmount);
    await staking.deposit(depositAmount);
    const certificateTokenAddress = await staking.certificateToken();
    const certificateTokenContract = await ethers.getContractFactory("CertificateToken");
    const certificateToken = await certificateTokenContract.attach(certificateTokenAddress);
    expect(await certificateToken.balanceOf(await owner.getAddress())).to.equal(depositAmount);
    // round 0
    await staking.setWithdrawConfig(limit, startTime);
    await expect(staking.withdraw(limit + BigInt(1))).to.be.revertedWith('CertificateStaking: withdraw: Withdraw has not started yet');
    await time.increaseTo(startTime);
    await expect(staking.withdraw(limit + BigInt(1))).to.be.revertedWith('CertificateStaking: withdraw: Withdraw limit exceeded');
    await staking.withdraw(limit);
    expect(await certificateToken.balanceOf(await owner.getAddress())).to.equal(depositAmount - limit);
  }
  describe("test certificate", function () {
    it("Init contract", async function () {
      await stake();
    });
  });
});
