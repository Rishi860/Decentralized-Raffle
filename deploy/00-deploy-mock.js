const { network } = require("hardhat");
const { developmentChains } = require("../helper-hardhat-config");

const BASE_FEE = ethers.utils.parseEther("0.25"); // 0.25 is the premium. it costs 0.25 LINK/request
const GAS_PRICE_LINK = 1e9; // 1000000000 // calculated value based on the gas price of the chain

// let say eth goes up by a lot
// chainlink nodes pay the gas fees to give us the randomness & do external calculations
// So they price of requests change based on the price of gas

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const args = [BASE_FEE, GAS_PRICE_LINK];

  if(developmentChains.includes(network.name)) {
    console.log("Deploying mocks...");
    // deploy mock VrfCoordinator
    await deploy("VRFCoordinatorV2Mock", {
      from: deployer,
      args: args,
      log: true,
    })

    log("MOcks deployed...")
    log("------------------------------------------------");
  }
};

module.exports.tags = ["all", "mocks"];
