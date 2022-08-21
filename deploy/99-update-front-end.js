// this script is for preparing a folder in front end which used some of the backend data

const { ethers, network } = require("hardhat");
const fs = require("fs")
const FRONT_END_ADDRESS_FILE = "../nextjs-smartcontract-lottery/constants/contractAddress.json";
const FRONT_END_ABI_FILE = "../nextjs-smartcontract-lottery/constants/abi.json";

module.exports = async function (){
  if(process.env.UPDATE_FRONT_END){
    console.log("Updating front end");
    updateContractAddress();
    updateAbi();
  }
}

async function updateAbi() {
  const raffle = await ethers.getContract("Raffle");
  fs.writeFileSync(FRONT_END_ABI_FILE, raffle.interface.format(ethers.utils.FormatTypes.json)); // second args is the changes we need to make

}

async function updateContractAddress(){
  const raffle = await ethers.getContract("Raffle");
  const currentAddress = JSON.parse(fs.readFileSync(FRONT_END_ADDRESS_FILE, "utf8"));
  const chainId = network.config.chainId.toString();
  if(chainId in currentAddress) { // checking if chain id is present in file or not
    if(!currentAddress[chainId].includes(raffle.address)){ // seeing if file includes address
      currentAddress[chainId].push(raffle.address); // address are stored in array 
    }
  } else {
    currentAddress[chainId] = [raffle.address];
  }
  fs.writeFileSync(FRONT_END_ADDRESS_FILE, JSON.stringify(currentAddress));
}

module.exports.tags = ["all", "frontend"]