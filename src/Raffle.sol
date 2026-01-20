// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {VRFConsumerBaseV2Plus} from
"@chainlink/contracts/src/v0.8/vrf/dev/VRFConsumerBaseV2Plus.sol";

import {VRFV2PlusClient} from
"@chainlink/contracts/src/v0.8/vrf/dev/libraries/VRFV2PlusClient.sol";


/***
 * @title A sample Raffle contract
 * @author Gintoki Sakata
 * @notice This contract is for creating and other functionality of raffle 
 * @dev Implements ChainlinkVRF@v2.5
 */
contract Raffle is VRFConsumerBaseV2Plus{
    /** Custom Errors */
    error Raffle__NotEnoughToEnterRaffle();
    error Raffle__NotEnoughTimePassed();
    error Raffle__TransferFailed();
    error Raffle__RaffleNotOpen();
    error Raffle__UpkeepNotNeeded(uint256 balance, uint256 playersLength, uint256 raffleState);

    /** Type Declarations */
    enum RaffleState {
        OPEN, // 0
        CALCULATING // 1
    }
    
    /** State Variable Declarations */
    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    uint256 private immutable I_ENTRANCE_FEE;
    bytes32 private immutable i_keyHash;
    uint256 private immutable i_vrfSubscriptionId;
    // @dev The duration of lottery in seconds
    uint256 private immutable i_interval;
    uint32 private immutable i_callbackGasLimit;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;
    address private s_recentWinner;
    RaffleState private s_raffleState;

    /** Events */
    event RaffleEntered(address indexed player);
    event WinnterPicked(address indexed winner);


    constructor(
        uint256 entrancefee,
        uint256 interval, 
        address vrfCoordinator, 
        bytes32 gasLane, 
        uint256 subscriptionId, 
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2Plus(vrfCoordinator) {
        I_ENTRANCE_FEE = entrancefee;
        i_interval = interval;
        i_keyHash = gasLane;
        i_vrfSubscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;

        s_lastTimeStamp = block.timestamp;
        s_raffleState = RaffleState.OPEN;

    }

    /** Public and External Functions  */
    function enterRaffle() public payable {
        if(msg.value < I_ENTRANCE_FEE) {
            revert Raffle__NotEnoughToEnterRaffle();
        }
        if(s_raffleState != RaffleState.OPEN) {
            revert Raffle__RaffleNotOpen();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }


    // 1. Get a random number 
    // 2. Use random number to pick a winner
    // 3. Be automatically called 


    function fulfillRandomWords(uint256 requestId , uint256[] calldata randomWords) internal override {
    //pick a winner here, send him the reward and reset the raffle

        // Effects (Internal Contract Interactions)
        uint256 indexOfplayer = randomWords[0] % s_players.length;
        address payable recentWinner = s_players[indexOfplayer];
        s_recentWinner = recentWinner;
        s_raffleState = RaffleState.OPEN;
        s_players = new address payable[](0);
        s_lastTimeStamp = block.timestamp; // to reset our interval clock
        emit WinnterPicked(recentWinner);

        // Interactions ( External Contract Interactions )       
        (bool success,) = recentWinner.call{value : address(this).balance}("");
        if(!success) {
            revert Raffle__TransferFailed();
        } 



    }

    /**
     * @dev This is the function that Chainlink node will call to see if lottery is ready    
       to pick winner
     * Following should be true in order to upkeepNeeded to be true :
     * 1. The time interval has passed between raffle runs
     * 2. contract has ETH
     * 3. lottery is open
     * 4. Implicitly , your chain vrf subscription has LINK
     * @return upkeepNeeded - true if it's time to restart the lottery
     */
    function checkUpkeep(bytes memory /** checkData */ )
        public 
        view 
        returns (bool upkeepNeeded, bytes memory /** checkData */) 
    {
        bool timesHasPassed = (block.timestamp - s_lastTimeStamp) >= i_interval ;
        bool isOpen = s_raffleState == RaffleState.OPEN;
        bool hasBalance  = address(this).balance > 0;
        bool hasPlayers = s_players.length > 0;

        upkeepNeeded = timesHasPassed && isOpen && hasBalance && hasPlayers ;
        return (upkeepNeeded, "");
    }

    function performUpkeep(bytes calldata /** performData */) public {

        (bool upkeepNeeded,) = checkUpkeep("");
        if(!upkeepNeeded) {
            revert Raffle__UpkeepNotNeeded(address(this).balance, s_players.length, uint256(s_raffleState));
        }

        s_raffleState = RaffleState.CALCULATING;

        VRFV2PlusClient.RandomWordsRequest memory request = VRFV2PlusClient.RandomWordsRequest({
                keyHash: i_keyHash,
                subId: i_vrfSubscriptionId,
                requestConfirmations: REQUEST_CONFIRMATIONS,
                callbackGasLimit: i_callbackGasLimit,
                numWords: NUM_WORDS,
                extraArgs: VRFV2PlusClient._argsToBytes(VRFV2PlusClient.ExtraArgsV1({nativePayment: true}))
            });

        uint256 requestId = s_vrfCoordinator.requestRandomWords(
            request
        );

    }

    /** Getter Functions */


    function getEntranceFee() external view returns(uint256) {
        return I_ENTRANCE_FEE ;
    }
}