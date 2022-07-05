const { expect } = require("chai");
const { ethers } = require("hardhat");
const hre = require("hardhat");
const util = require('util')

var factoryContract = null;
var iyal, iyaico;
var owner, addr1;


const timer = util.promisify(setTimeout);

describe("Deploy Token and Contract", function () {

  it("Deploy Token", async function () {
    [owner, addr1] = await ethers.getSigners();
    owner_addr = owner.address;

    const IYAL = await hre.ethers.getContractFactory("IYAL");
    iyal = await IYAL.deploy();
    await iyal.deployed();
  });

  it("Deploy ICO Contract", async function () {
    const IYAICO = await hre.ethers.getContractFactory("IYAICO");
    iyaico = await IYAICO.deploy();
    await iyaico.deployed();
  });

  it("Set Token/ICO Address", async function () {
    await iyal.setICOAddress(iyaico.address);
    await iyaico.setToken(iyal.address);
  });

  it("Set ICO Endtime", async function () {
    var timestamp = new Date().getTime();
    timestamp = (timestamp - timestamp % 1000) / 1000 + 3600;
    await iyaico.setEndTime(timestamp);
    const currentEndtime = await iyaico.ICO_ENDTIME();
    expect(currentEndtime).to.equal(timestamp);
  });

  it("Send IYA to ICO Contract", async function () {
    iyal.transfer(iyaico.address, "10000000000000000000000000");
    expect(await iyal.balanceOf(iyaico.address)).to.equal("10000000000000000000000000");
  });

  it("Buy IYA from ICO contract", async function () {
    await iyaico.buy("0x42F9dcd93DDCB82ED531A609774F6304275DeeaD", {value: "20000000000000000"});
    expect(await iyal.balanceOf(owner.address)).to.equal("500000000");
  });

  it("Airdrop fails before ICO Ends", async function () {
    expect(iyaico.airdrop("0x42F9dcd93DDCB82ED531A609774F6304275DeeaD", {value: "2000000000000000"})).to.be.revertedWith("")
  });

  it("Airdrop success after ICO Ends", async function () {
    var timestamp = new Date().getTime();
    timestamp = (timestamp - timestamp % 1000) / 1000 - 3600;
    await iyaico.setEndTime(timestamp);
    await iyaico.airdrop("0x42F9dcd93DDCB82ED531A609774F6304275DeeaD", {value: "2000000000000000"});

    expect(await iyal.balanceOf(owner.address)).to.equal("5000000000500000000");
  });

  it("Buy IYA from ICO contract Failes after ICO Ends", async function () {
    expect(iyaico.buy("0x42F9dcd93DDCB82ED531A609774F6304275DeeaD", {value: "20000000000000000"})).to.be.revertedWith("");
  });
});
