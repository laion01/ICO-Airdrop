const hre = require("hardhat");
require("color");

async function main() {

  const IYAL = await hre.ethers.getContractFactory("IYAL");
  const iyal = await IYAL.deploy();
  await iyal.deployed();
  console.log("IYAL Address:", iyal.address);

  const IYAICO = await hre.ethers.getContractFactory("IYAICO");
  const iyaico = await IYAICO.deploy();
  await iyaico.deployed();
  console.log("IYAL-ICO Address:", iyaico.address);

  await iyal.setICOAddress(iyaico.address);
  await iyaico.setToken(iyal.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
