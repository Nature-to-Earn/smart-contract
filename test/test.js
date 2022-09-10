const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
// import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
// import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
// import { expect } from "chai";
// import { ethers } from "hardhat";

describe("Wilderr testing", function () {
  let deployer, addr1, addr2, addr3, addr4, addr5, addr6, addr7;

  before(async function () {
    [deployer, addr1, addr2, addr3, addr4, addr5, addr6, addr7] =
      await ethers.getSigners();

    const WilderrFactory = await ethers.getContractFactory("Wilderr");
    this.contract = await WilderrFactory.deploy([
      addr1.address,
      addr2.address,
      addr3.address,
      addr4.address,
      addr5.address,
      addr6.address,
      addr7.address,
    ]);
  });

  /* *************** TESTING DAO SECTION ****************** */

  it("check DAO member status", async function () {
    let arr = [addr1, addr2, addr3, addr4, addr5, addr6, addr7];
    let res = true;
    arr.forEach(async (a) => {
      let temp = await this.contract.DAO_membership_status_mapping(a);
      if (temp != 2) {
        res = false;
      }
    });
    const DAO_members_count = await this.contract.totalDaoMembers();

    expect(res).to.be.equal(true);
    expect(DAO_members_count).to.be.equal(7);
  });
  it("check 'registerInDAO'", async function () {
    let res_1 = await this.contract.DAO_membership_status_mapping(
      deployer.address
    );
    await this.contract.connect(deployer).registerInDAO(deployer.address);
    let res_2 = await this.contract.DAO_membership_status_mapping(
      deployer.address
    );
    await this.contract.connect(addr1).voteForDaoMembership(1, true);
    await this.contract.connect(addr2).voteForDaoMembership(1, true);
    await this.contract.connect(addr3).voteForDaoMembership(1, true);
    await this.contract.connect(addr4).voteForDaoMembership(1, true);
    await this.contract.connect(addr5).voteForDaoMembership(1, false);
    await this.contract.connect(addr6).voteForDaoMembership(1, false);
    await this.contract.connect(addr7).voteForDaoMembership(1, false);

    await network.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);

    await this.contract.connect(addr1).make_DAO_member(1);
    let res_3 = await this.contract.DAO_membership_status_mapping(
      deployer.address
    );
    expect(res_1).to.be.equal(0);
    expect(res_2).to.be.equal(1);
    expect(res_3).to.be.equal(2);
  });
  it("check 'registerEvent'", async function () {
    await this.contract
      .connect(deployer)
      .registerEvent("my_metadata_uri", 20, "winterland", 1000);

    await this.contract.connect(addr1).voteForEvent(1, true);
    await this.contract.connect(addr2).voteForEvent(1, true);
    await this.contract.connect(addr3).voteForEvent(1, true);
    await this.contract.connect(addr4).voteForEvent(1, true);
    await this.contract.connect(addr5).voteForEvent(1, false);
    await this.contract.connect(addr6).voteForEvent(1, false);
    await this.contract.connect(addr7).voteForEvent(1, false);

    await network.provider.send("evm_increaseTime", [3 * 24 * 60 * 60]);

    await this.contract.connect(deployer).countVotes(1);
    let obj = await this.contract.event_proposals(1);

    expect(obj.status).to.be.equal(2); //event is approved if status is 2
  });
});
