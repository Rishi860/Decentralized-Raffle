const { assert, expect } = require("chai");
const { network, getNamedAccounts, deployments, ethers } = require("hardhat");
const { developmentChains, networkConfig } = require("../../helper-hardhat-config");

developmentChains.includes(network.name)
  ? describe.skip
  : describe("Raffle unit test", function () {
      let raffle, raffleEntranceFee, deployer;

      beforeEach(async function () {
        deployer = (await getNamedAccounts()).deployer;
        raffle = await ethers.getContract("Raffle", deployer);
        raffleEntranceFee = await raffle.getEntranceFee();
      });
      describe("fulfillRandomWords", function () {
        it("works with live chainlink keepers and chainlink VRF, we get a random winner", async function () {
          // enter the raffle
          console.log("in here staging test");
          const startingTimeStamp = await raffle.getLatestTimeStamp();
          const accounts = await ethers.getSigners();
          console.log("before promise created");
          await new Promise(async (resolve, reject) => {
            // setting up listener before we enter the raffle
            console.log("in promise before listener triggered");
            raffle.once("WinnerPicked", async () => {
              console.log("winner picked event fired");
              try {
                // add our asserts here
                const recentWinner = await raffle.getRecentWinner();
                const raffleState = await raffle.getRaffleState();
                const winnerEndingBalance = await accounts[0].getBalance();
                const endingTimeStamp = await raffle.getLatestTimeStamp();

                await expect(raffle.getPlayer(0)).to.be.reverted;
                assert.equal(recentWinner.toString(), accounts[0].address);
                assert.equal(raffleState.toString(), "0");
                assert.equal(
                  winnerEndingBalance.toString(),
                  winnerStartingalance.add(raffleEntranceFee).toString()
                );
                assert(endingTimeStamp > startingTimeStamp);
                resolve();
              } catch (e) {
                console.log(e);
                reject(e);
              }
            });
            // then entering the raffle

            console.log("Should start the process of entering in raffle");
            const tx = await raffle.enterRaffle({ value: raffleEntranceFee });
            await tx.wait(1); // this gives my account time to adjust balance: adjusting gas fee
            console.log("must have entered the raffle");
            const winnerStartingalance = await accounts[0].getBalance();
          });
        });
      });
    });
