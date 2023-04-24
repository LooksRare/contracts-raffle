# @looksrare/contracts-raffle

[![Tests](https://github.com/LooksRare/contracts-raffle/actions/workflows/tests.yaml/badge.svg)](https://github.com/LooksRare/contracts-raffle/actions/workflows/tests.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Description

This project contains the smart contracts used for LooksRare's raffle protocol. The main contract `Raffle`
allows anyone to create a raffle with multiple prizes and winners. The fees must be paid in ETH or ERC-20, while
the prizes can be ERC-721, ERC-1155, ETH or ERC-20.

### Raffle states

Each raffle consists of the following states:

1. None
   There is no raffle at the provided ID.

2. Created
   The raffle has been created, but the prizes have not been deposited.

3. Open
   The prizes have been deposited and is open for entries.

4. Drawing
   When a raffle's minimum entries has reached before the cutoff time, the smart contract calls Chainlink VRF
   to draw multiple random numbers to determine the winners. The state `Drawing` represents the intermediary state
   of waiting for Chainlink VRF's callback.

5. RandomnessFulfilled
   When Chainlink VRF's callback is complete, the raffle stores the random words and transitions to `RandomnessFulfilled`.

6. Drawn
   The process to store random words and to select the winners are separated into 2 functions as there is a 2.5m callback gas limit
   from Chainlink. Once the winners are selected via the function `selectWinners`, the raffle is considered `Drawn`.

7. Complete
   After the raffle creator claims the fees accumulated from selling raffle tickets, the raffle is considered `Complete`.

8. Cancelled
   If the raffle is still in the `Created` state (no prizes were deposited) or is not able to sell out at least the specified minimum entries, then the raffle can be cancelled. Once the raffle is cancelled, the raffle creator can withdraw the prizes deposited (if any) and the ticket buyers can withdraw the fees spent (if any).

### Protocol fees

The contract owner can set a protocol fee recipient and a protocol fee basis points (up to 25%) per raffle.

### Pricing options

Each raffle must have exactly 5 pricing options. The rules are as follows:

1. The first pricing option must have a entries count of 1.
2. The first pricing option must not have a price of 0.
3. Each pricing option after the first one must have a higher entries count than the previous one.
4. Each pricing option after the first one must have a higher **total price** than the previous one.
5. Each pricing option after the first one must have a lower **price per entry** than the previous one.

### Misc. rules

1. Each raffle's lifespan must between 1 day to 7 days.
2. If the fee/prize token is an ERC-20, then it must be allowed by the contract owner (LooksRare's multi-sig).
3. There can be up to 20 prizes per raffle. Each ERC-721 prize counts as 1 even if they belong to the same collection.
   Each ERC-20 / ERC-1155 with the same token ID and multiple winners count as 1.
4. The maximum winners per raffle is 110.
