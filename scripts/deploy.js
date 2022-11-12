// import { ethers } from "hardhat";
const { ethers } = require("hardhat");
const { mine } = require("@nomicfoundation/hardhat-network-helpers");

async function main() {
  const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  const [deployer, addr1, addr2, addr3, addr4, addr5, addr6, addr7, addr8] =
    await ethers.getSigners();

  const n2eFactory = await ethers.getContractFactory("n2e");
  const n2e = await n2eFactory.deploy(
    [
      deployer.address,
      addr1.address,
      addr2.address,
      addr3.address,
      addr4.address,
      addr5.address,
      addr6.address,
    ],
    addr7.address
  );
  console.log("n2e contract is deployed at : ", n2e.address);

  // Register event
  let tx = await n2e.registerEvent("abcd", 10, "winterland", 1000);
  await tx.wait();
  tx = await n2e.connect(addr7).registerEvent("abcd", 12, "holaNala", 1200);
  await tx.wait();
  tx = await n2e.connect(addr8).registerEvent("abcd", 13, "NalaSupara", 1300);
  await tx.wait();
  tx = await n2e.connect(addr7).registerEvent("abcd", 9, "DJNacho", 900);
  await tx.wait();

  let totalEvents = (await n2e.next_event_proposal()) - 1;
  await mine(100);

  for (let i = 1; i <= totalEvents; i++) {
    if (i % 2 != 0) {
      tx = await n2e.connect(deployer).voteForEvent(i, true);
      tx.wait();
      tx = await n2e.connect(addr1).voteForEvent(i, true);
      tx.wait();
      tx = await n2e.connect(addr2).voteForEvent(i, true);
      tx.wait();
      tx = await n2e.connect(addr3).voteForEvent(i, true);
      tx.wait();
      tx = await n2e.connect(addr4).voteForEvent(i, false);
      tx.wait();
      tx = await n2e.connect(addr5).voteForEvent(i, false);
      tx.wait();
      tx = await n2e.connect(addr6).voteForEvent(i, false);
      tx.wait();
    } else {
      tx = await n2e.connect(deployer).voteForEvent(i, false);
      tx.wait();
      tx = await n2e.connect(addr1).voteForEvent(i, false);
      tx.wait();
      tx = await n2e.connect(addr2).voteForEvent(i, false);
      tx.wait();
      tx = await n2e.connect(addr3).voteForEvent(i, false);
      tx.wait();
      tx = await n2e.connect(addr4).voteForEvent(i, true);
      tx.wait();
      tx = await n2e.connect(addr5).voteForEvent(i, true);
      tx.wait();
      tx = await n2e.connect(addr6).voteForEvent(i, true);
      tx.wait();
    }
  }
  await hre.network.provider.send("hardhat_mine", ["0x100"]);
  await network.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);
  for (let i = totalEvents; i > 0; i--) {
    tx = await n2e.countVotes(i);
    await tx.wait();
  }
  for (let i = totalEvents; i > 0; i--) {
    tx = await n2e.getEventDetails(i);
    console.log(tx);
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
