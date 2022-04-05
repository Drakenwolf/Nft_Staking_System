const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Staking of one nft", function () {
  it("Should stake an nft and console.log the reward for the first staking cycle", async function () {
    const [owner, addr1] = await ethers.getSigners();

    const deployer = owner.address;
    const nullAddress = "0x0000000000000000000000000000000000000000";
    const account1 = addr1.address;

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

    // setting approval for all in the nft contract to the staking system contract
    console.log((StakingSystemContract.address, account1, 0));
    await expect(
      RandomApeContract.setApprovalForAll(StakingSystemContract.address, true)
    )
      .to.emit(RandomApeContract, "ApprovalForAll")
      .withArgs(deployer, StakingSystemContract.address, true);

    console.log("StakingSystem deployed: ", StakingSystemContract.address);

    //mint 2 nfts

    await expect(RandomApeContract.safeMint(account1, "ipfs::/test/"))
      .to.emit(RandomApeContract, "Transfer")
      .withArgs(nullAddress, account1, 0);

    await expect(RandomApeContract.safeMint(account1, "ipfs::/test/"))
      .to.emit(RandomApeContract, "Transfer")
      .withArgs(nullAddress, account1, 1);

    await StakingSystemContract.initStaking();
    await StakingSystemContract.setTokensClaimable(true);

    //stake 1 token
    // signed by account1\

    // we need the staker to setApproval for all to the staking system contract
    await expect(
      RandomApeContract.connect(addr1).setApprovalForAll(
        StakingSystemContract.address,
        true
      )
    )
      .to.emit(RandomApeContract, "ApprovalForAll")
      .withArgs(account1, StakingSystemContract.address, true);

    await expect(StakingSystemContract.connect(addr1).stake(0))
      .to.emit(StakingSystemContract, "Staked")
      .withArgs(account1, 0);

    // look a way to increase time in this test



    await network.provider.send("evm_increaseTime", [200])
    await network.provider.send("evm_mine")
    
     console.log("Updating reward: ");
     await StakingSystemContract.connect(addr1).updateReward(account1);

     await StakingSystemContract.connect(addr1).claimReward(account1);

  });
});
