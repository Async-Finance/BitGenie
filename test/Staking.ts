import { time } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { expect } from 'chai';
import { ethers } from 'hardhat';

const HARD_CAP = BigInt(1000 * 10 ** 18);

describe("Staking", function () {
  async function initContractFixture() {
    const [owner] = await ethers.getSigners();
    const EMPToken = await ethers.getContractFactory("EMP");
    let EMP = await EMPToken.deploy(1000000000);
    EMP = await EMP.waitForDeployment();
    const MBTCToken = await ethers.getContractFactory("MBTC");
    let MBTC = await MBTCToken.deploy(1000000000);
    MBTC = await MBTC.waitForDeployment();
    const StakingContract = await ethers.getContractFactory("Staking");
    const stakeTokenAddress = await MBTC.getAddress();
    const rewardTokenAddress = await EMP.getAddress();
    const startTime = (await time.latest()) + 60;
    const endTime = startTime + 60 * 60;
    const withdrawDelay = 60 * 60 * 2;
    let staking = await StakingContract.deploy(stakeTokenAddress, rewardTokenAddress, startTime, endTime, HARD_CAP.toString());
    staking = await staking.waitForDeployment();
    const rewardAmount = BigInt(1000 * 10 ** 18);
    await EMP.transfer(await staking.getAddress(), rewardAmount.toString());
    await staking.setWithdrawDelay(withdrawDelay);
    await staking.setRewardPerTokenPerSecond();
    expect(await staking.rewardPerTokenPerSecond()).to.equal(BigInt(10 ** 18) * rewardAmount / HARD_CAP / 3600n);
    const stakeValue = BigInt(88 * 10 ** 18);
    await expect(staking.stake(stakeValue.toString())).to.be.revertedWith('StakingFund doesn\'t have enough allowance');
    // stake
    await MBTC.approve(await staking.getAddress(), stakeValue.toString());
    await time.increaseTo(startTime);
    expect(await MBTC.allowance(await owner.getAddress(), await staking.getAddress())).to.equal(stakeValue.toString());
    await staking.stake(stakeValue.toString());
    await expect(staking.redeem()).to.be.revertedWith('Cannot Redeem.');
    await time.increaseTo(endTime);
    await staking.redeem();
    await expect(staking.unstake((stakeValue + BigInt(1)).toString())).to.be.revertedWith('Exceeds balance');
    await staking.unstake(stakeValue.toString());
    await expect(staking.withdraw(stakeTokenAddress)).to.be.revertedWith('Cannot withdraw');
    await time.increaseTo(endTime + withdrawDelay);
    await expect(staking.withdraw(stakeTokenAddress)).to.be.revertedWith('Cannot withdraw stake token');
    await staking.withdraw(rewardTokenAddress);
  }

  describe("Deployment", function () {
    it("Init contract", async function () {
      await initContractFixture();
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
