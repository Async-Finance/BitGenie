import { time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';


describe("CeritficateStaking", function () {

  async function stake() {
    const [owner] = await ethers.getSigners();
    const EMPToken = await ethers.getContractFactory("EMP");
    let EMP = await EMPToken.deploy(1000000000);
    EMP = await EMP.waitForDeployment();
    const stakingContract = await ethers.getContractFactory("CertificateStaking");
    let staking = await stakingContract.deploy(await EMP.getAddress(), 'PEMP Token', 'PEMP');
    staking = await staking.waitForDeployment();
    let round = BigInt(0);
    let limit = BigInt(20 * 10 ** 18);
    let startTime = await time.latest();

    const depositAmount = BigInt(100000000 * 10 ** 18);

    await EMP.approve(await staking.getAddress(), depositAmount);
    await staking.deposit(depositAmount);
    const certificateTokenAddress = await staking.certificateToken();
    const certificateTokenContract = await ethers.getContractFactory("CertificateToken");
    const certificateToken = await certificateTokenContract.attach(certificateTokenAddress);
    expect(await certificateToken.balanceOf(await owner.getAddress())).to.equal(depositAmount);
    // round 0
    await staking.setWithdrawConfig(limit, startTime);
    await expect(staking.withdraw(limit + BigInt(1))).to.be.revertedWith('CertificateStaking: withdraw: Withdraw limit exceeded');
    await staking.withdraw(limit);
    expect(await certificateToken.balanceOf(await owner.getAddress())).to.equal(depositAmount - limit);
  }
  describe("test certificate", function () {
    it("Init contract", async function () {
      await stake();
    });

  //   it("Should set the right owner", async function () {
  //     const { lock, owner } = await loadFixture(deployOneYearLockFixture);
  //
  //     expect(await lock.owner()).to.equal(owner.address);
  //   });
  //
  //   it("Should receive and store the funds to lock", async function () {
  //     const { lock, lockedAmount } = await loadFixture(
  //       deployOneYearLockFixture
  //     );
  //
  //     expect(await ethers.provider.getBalance(lock.target)).to.equal(
  //       lockedAmount
  //     );
  //   });
  //
  //   it("Should fail if the unlockTime is not in the future", async function () {
  //     // We don't use the fixture here because we want a different deployment
  //     const latestTime = await time.latest();
  //     const Lock = await ethers.getContractFactory("Lock");
  //     await expect(Lock.deploy(latestTime, { value: 1 })).to.be.revertedWith(
  //       "Unlock time should be in the future"
  //     );
  //   });
  // });
  //
  // describe("Withdrawals", function () {
  //   describe("Validations", function () {
  //     it("Should revert with the right error if called too soon", async function () {
  //       const { lock } = await loadFixture(deployOneYearLockFixture);
  //
  //       await expect(lock.withdraw()).to.be.revertedWith(
  //         "You can't withdraw yet"
  //       );
  //     });
  //
  //     it("Should revert with the right error if called from another account", async function () {
  //       const { lock, unlockTime, otherAccount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       // We can increase the time in Hardhat Network
  //       await time.increaseTo(unlockTime);
  //
  //       // We use lock.connect() to send a transaction from another account
  //       await expect(lock.connect(otherAccount).withdraw()).to.be.revertedWith(
  //         "You aren't the owner"
  //       );
  //     });
  //
  //     it("Shouldn't fail if the unlockTime has arrived and the owner calls it", async function () {
  //       const { lock, unlockTime } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       // Transactions are sent using the first signer by default
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw()).not.to.be.reverted;
  //     });
  //   });
  //
  //   describe("Events", function () {
  //     it("Should emit an event on withdrawals", async function () {
  //       const { lock, unlockTime, lockedAmount } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw())
  //         .to.emit(lock, "Withdrawal")
  //         .withArgs(lockedAmount, anyValue); // We accept any value as `when` arg
  //     });
  //   });
  //
  //   describe("Transfers", function () {
  //     it("Should transfer the funds to the owner", async function () {
  //       const { lock, unlockTime, lockedAmount, owner } = await loadFixture(
  //         deployOneYearLockFixture
  //       );
  //
  //       await time.increaseTo(unlockTime);
  //
  //       await expect(lock.withdraw()).to.changeEtherBalances(
  //         [owner, lock],
  //         [lockedAmount, -lockedAmount]
  //       );
  //     });
  //   });
  });
});
