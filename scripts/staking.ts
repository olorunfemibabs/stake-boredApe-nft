import { ethers, network } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber } from "ethers";

async function main() {

    const [owner] = await ethers.getSigners();

    const Stake = await ethers.getContractFactory("StakeERC721");
    const stake = await Stake.deploy();
    await stake.deployed();

    const stakeContract = stake.address;
    console.log(`staking contract address ${stakeContract}`);

    const mint = ethers.utils.parseEther("1000");
    const Reward = await ethers.getContractFactory("rewardToken");
    const reward = await Reward.deploy("REWARD", "RWD", mint, stakeContract);
    await reward.deployed();
    const rewardTokenAddress = reward.address;
    console.log(`reward contract address ${rewardTokenAddress}`)

    const setRewardToken = await stake.setTokenAddress(rewardTokenAddress);

    const helpers = require("@nomicfoundation/hardhat-network-helpers");

    const boredApeHolder = "0x4A385286592C97e457A6f54A3734557F4b095A28";

    const address = boredApeHolder;

    await helpers.impersonateAccount(address);

    const impersonatedSigner = await ethers.getSigner(address);

    await helpers.setBalance(address, 10000000000000000000000000)


  const DAI = "0x6B175474E89094C44Da98b954EedeAC495271d0F";

  /// connect dai
  const dai = await ethers.getContractAt("IDAI", DAI);

  const approve = dai.connect(impersonatedSigner).approve(stakeContract, mint);

  const amount = ethers.utils.parseEther("0.5");
    const userBalanceBefore = await dai.balanceOf(impersonatedSigner.address);
    console.log(`balance before staking ${userBalanceBefore}`);

    const staker = await stake.connect(impersonatedSigner).stake(1000000000);
    console.log(`staked successfully`);

    const userBalanceAfter = await dai.balanceOf(impersonatedSigner.address);

    console.log(`balance after staking ${userBalanceAfter}`);

    const contractBalance = await dai.balanceOf(stakeContract)
    console.log(` contract dai balance ${contractBalance}`);

    const updateReward = await stake.connect(impersonatedSigner).updateReward();
    const rewarded = await stake.connect(impersonatedSigner).displayReward();
    console.log(`user reward ${rewarded}`);

    console.log(`time warp started..................`)
    const wapTime = await ethers.provider.send("evm_mine", [1709251199]);
    console.log(`time warp completed..................`)


    console.log(`Attempting reward withdrawal..................`)
    const ClaimReward = await stake.connect(impersonatedSigner).claimReward(90000000);
    console.log(`Reward withdrawal completed..................`)

    console.log(`Attempting Stake withdrawal..................`)
    const withdraw = await stake.connect(impersonatedSigner).withdrawStaked(1000000000);
    console.log(`Stake withdrawal completed..................`)

  const userInfoAfter = await stake.userInfo(impersonatedSigner.address);
  console.log(`holder information ${userInfoAfter}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});