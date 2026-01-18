// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;


/***
 * @title A sample Raffle contract
 * @author Gintoki Sakata
 * @notice This contract is for creating and other functionality of raffle 
 * @dev Implements ChainlinkVRF@v2.5
 */
contract Raffle {
    error Raffle_NotEnoughToEnterRaffle();
    error Raffle_NotEnoughTimePassed();

    event RaffleEntered(address indexed player);
    

    uint256 private immutable I_ENTRANCE_FEE;
    // @dev The duration of lottery in seconds
    uint256 private immutable s_interval;
    address payable[] private s_players;
    uint256 private s_lastTimeStamp;

    constructor(uint256 entrancefee, uint256 interval) {
        I_ENTRANCE_FEE = entrancefee;
        s_interval = interval;
    }

    function enterRaffle() public payable {
        if(msg.value < I_ENTRANCE_FEE) {
            revert Raffle_NotEnoughToEnterRaffle();
        }
        s_players.push(payable(msg.sender));
        emit RaffleEntered(msg.sender);
    }


    // 1. Get a random number 
    // 2. Use random number to pick a winner
    // 3. Be automatically called 
    function pickWinner() public {

        if((block.timestamp - s_lastTimeStamp) < s_interval) {
            revert Raffle_NotEnoughTimePassed();
        }
    }


    /** Getter Functions */

    function getEntranceFee() external view returns(uint256) {
        return I_ENTRANCE_FEE ;
    }
}