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
});
