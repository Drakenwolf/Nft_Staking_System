const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking of one nft", function () {
  it("Should stake an nft and console.log the reward for the first staking cycle", async function () {
    const [owner, addr1] = await ethers.getSigners();

    const deployer = owner.address;

    /// factories
    const RandomApeFactory = await ethers.getContractFactory("RandomApe");
    const RewardTokenFactory = await ethers.getContractFactory("RewardToken");
    const StakingSystemFactory = await ethers.getContractFactory(
      "StakingSystem"
    );

    /// @notice that the nft and the toke are being deployed

    const RandomApeContract = await RandomApeFactory.deploy();
    const RewardTokenContract = await RewardTokenFactory.deploy();

    await RandomApeContract.deployed();
    await RewardTokenContract.deployed();

    // we use their address as parameters for the Staking system

    const StakingSystemContract = await StakingSystemFactory.deploy(
      RandomApeContract.address,
      RewardTokenContract.address
    );

    await expect(
      RandomApeContract.setApprovalForAll(StakingSystemContract.address, true)
    )
      .to.emit(RandomApeContract, "ApprovalForAll")
      .withArgs(deployer, StakingSystemContract.address, true);

    console.log("StakingSystem deployed: ", StakingSystemContract.address);
  });
});
