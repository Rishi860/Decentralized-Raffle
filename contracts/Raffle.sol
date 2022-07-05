// Raffle
// Enter the lottery amount
// Pick a random winner (verifiably random)
// winner to be selected every x minutes -> completely automate
// chain link oracle -> Randomness, Automated Execution (chainlink keeper)

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

error Raffle__NotEnoughETHEntered();
error Raffle__TransferFailed();
error Raffle__NotOpen();
error Raffle__UpKeepNotNeeded(uint256 currentbalance, uint256 numPlayers, uint256 raffleState);

/** @title A sample Raffle Contract
 *  @author Rishi khandelwal
 *  @notice This contract is for creating an untammperable decentralised smart contract
 *  @dev This implements chainlink VRF v2 and chainlink keepers
 */

contract Raffle is VRFConsumerBaseV2, KeeperCompatibleInterface {
  /* Type variables */
  enum RaffleState {
    OPEN,
    CALCULATING
  } // uint256 where 0=OPEN, 1=CALCULATING

  /* sTATE VARIABLES */
  uint256 immutable i_enteranceFee;
  address payable[] private s_players; // since we need to pay to one of these players so better to make em payabale
  VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
  bytes32 private immutable i_gasLane;
  uint64 private immutable i_subscriptionId;
  uint16 private constant REQUEST_CONFIRMATIONS = 3;
  uint32 private immutable i_callbackGasLimit;
  uint32 private constant NUM_WORDS = 1;

  /* Lottery Variable */
  address private s_recentWinner;
  RaffleState private s_raffleState;
  uint256 private s_lastTimeStamp;
  uint256 private immutable i_interval;

  /* Events */
  event RaffleEnter(address indexed player);
  event RequestedRaffleWinner(uint256 indexed requestId);
  event WinnerPicked(address indexed winner);

  // passing the constructor argument required by the VRFConsumerBaseV2 file
  constructor(
    address vrfCoordinatorV2,
    uint256 entranceFee,
    bytes32 gasLane,
    uint64 subscriptionId,
    uint32 callbackGasLimit,
    uint256 interval
  ) VRFConsumerBaseV2(vrfCoordinatorV2) {
    i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinatorV2);
    i_enteranceFee = entranceFee;
    i_gasLane = gasLane;
    i_subscriptionId = subscriptionId;
    i_callbackGasLimit = callbackGasLimit;
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
    i_interval = interval;
  }

  function enterRaffle() public payable {
    if (msg.value < i_enteranceFee) {
      revert Raffle__NotEnoughETHEntered();
    }
    if (s_raffleState != RaffleState.OPEN) {
      revert Raffle__NotOpen();
    }

    s_players.push(payable(msg.sender));
    // emit an event when we update a dynamic array or mapping
    // Named events with the function named reversed
    emit RaffleEnter(msg.sender);
  }

  /**
   * @dev This is the function that the chinlink keepers node call
   * that they look for the 'upkeepNeede' to return true.
   * The following should be true in order to return true
   * 1. Our time interval should have passed
   * 2. The lottery should have atleast one player, and have some ETH
   * 3. Our subscription is funded with LINK
   * 4. The lottery should be in open state.
   */
  function checkUpkeep(
    bytes memory /* checkData */
  )
    public
    override
    returns (
      bool upkeepNeeded,
      bytes memory /* performData */
    )
  {
    bool isOpen = (s_raffleState == RaffleState.OPEN);
    // block.timestamp // a global variable
    bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
    bool hasPlayers = (s_players.length > 0);
    bool hasBalance = (address(this).balance > 0);
    upkeepNeeded = (isOpen && timePassed && hasPlayers && hasBalance);
  }

  function performUpkeep(
    bytes calldata /* performData */
  ) external override {
    // check whether we need to perform upKeep or not
    (bool upKeepNeeded, ) = checkUpkeep(""); // calldata changed to memory type
    if (!upKeepNeeded) {
      revert Raffle__UpKeepNotNeeded(
        address(this).balance,
        s_players.length,
        uint256(s_raffleState)
      );
    }
    // Request the random number
    // Once we get the numbers, do something with it
    // 2 transaction process- makes it more secure

    s_raffleState = RaffleState.CALCULATING;

    uint256 requestId = i_vrfCoordinator.requestRandomWords(
      i_gasLane, // keyHash: for setting a upper bound to gas used for getting a random number
      i_subscriptionId, // we get it from chainlink as a id for our account to get randomNumbers
      REQUEST_CONFIRMATIONS, // NO OF NODES CHAINLINK SHOULD WAIT BEFORE UPDATING
      i_callbackGasLimit, // this is for setting a limit on how much we can spend on fulfillRandomWords function
      NUM_WORDS // number of random words we want
    );

    // this is redundant vrf coordinator file already did that
    emit RequestedRaffleWinner(requestId);
  }

  // this is a override function provided to VRFConsumerBaseV2 file to work upon
  // if we dont need an argument but the files requires it we can just comment it out
  function fulfillRandomWords(
    uint256, /*requestId*/
    uint256[] memory randomWords
  ) internal override {
    uint256 indexOfWinner = randomWords[0] % s_players.length;
    address payable winner = s_players[indexOfWinner];
    s_recentWinner = winner;
    s_players = new address payable[](0);
    s_raffleState = RaffleState.OPEN;
    s_lastTimeStamp = block.timestamp;
    (bool success, ) = winner.call{value: address(this).balance}("");
    // require instead gas efficient
    if (!success) {
      revert Raffle__TransferFailed();
    }
    emit WinnerPicked(winner);
  }

  /* View/pure */
  function getEntranceFee() public view returns (uint256) {
    return i_enteranceFee;
  }

  function getPlayer(uint256 index) public view returns (address) {
    return s_players[index];
  }

  function getRecentWinner() public view returns (address) {
    return s_recentWinner;
  }

  function getRaffleState() public view returns (RaffleState) {
    return s_raffleState;
  }

  // pure because its just a number not even stored in our storage so pure can be used instead of view
  function getNumWords() public pure returns (uint256) {
    return NUM_WORDS;
  }

  function getNumberOfPlayers() public view returns(uint256) {
    return s_players.length;
  }

  function getLatestTimeStamp() public view returns(uint256) {
    return s_lastTimeStamp;
  }

  function getRequestConfirmations() public pure returns(uint256) {
    return REQUEST_CONFIRMATIONS;
  }

  function getInterval() public view returns(uint256) {
    return i_interval;
  }
}
