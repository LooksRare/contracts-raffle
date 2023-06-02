# @looksrare/contracts-raffle

[![Tests](https://github.com/LooksRare/contracts-raffle/actions/workflows/tests.yaml/badge.svg)](https://github.com/LooksRare/contracts-raffle/actions/workflows/tests.yaml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Description

This project contains the smart contracts used for LooksRare's raffle protocol. The main contract `Raffle`
allows anyone to create a raffle with multiple prizes and winners. The fees must be paid in ETH or ERC-20, while
the prizes can be ERC-721, ERC-1155, ETH or ERC-20.

## Deployments

| Network  | Raffle                                                                                                                             |
| :------- | :--------------------------------------------------------------------------------------------------------------------------------- |
| Ethereum | [0x0000000000009703EcD0fFEa3143fc9096DE91B0](https://etherscan.io/address/0x0000000000009703EcD0fFEa3143fc9096DE91B0#code)         |
| Goerli   | [0xC5F7FCde87e30Aa339d3d61B4fe3c1C261f6EEe2](https://goerli.etherscan.io/address/0xC5F7FCde87e30Aa339d3d61B4fe3c1C261f6EEe2#code)  |
| Sepolia  | [0xb0C8a1a0569F7302d36e380755f1835C3e59aCB9](https://sepolia.etherscan.io/address/0xb0C8a1a0569F7302d36e380755f1835C3e59aCB9#code) |

### Raffle states

Each raffle consists of the following states:

1. `None`
   There is no raffle at the provided ID.

2. `Open`
   The raffle has been created, prizes have been deposited and is open for entries.

3. `Drawing`
   When a raffle's minimum entries has reached before the cutoff time, the smart contract calls Chainlink VRF
   to draw multiple random numbers to determine the winners. The state `Drawing` represents the intermediary state
   of waiting for Chainlink VRF's callback.

4. `RandomnessFulfilled`
   When Chainlink VRF's callback is complete, the raffle stores the random words and transitions to `RandomnessFulfilled`.

5. `Drawn`
   The process to store random words and to select the winners are separated into 2 functions as there is a 2.5m callback gas limit
   from Chainlink. Once the winners are selected via the function `selectWinners`, the raffle is considered `Drawn`.

6. `Complete`
   After the raffle creator claims the fees accumulated from selling raffle tickets, the raffle is considered `Complete`.

7. `Refundable`
   If the raffle is still in the `Created` state (no prizes were deposited) or is not able to sell out at least the specified minimum entries, then the raffle can be cancelled. The raffle can be transitioned to `Refundable` state if there are deposited prizes. The raffle creator can withdraw the prizes and the ticket buyers can withdraw the fees spent (if any).

8. `Cancelled`
   A raffle can transition from `Refundable` to `Cancelled` by having the raffle creator withdrawing the prizes or it can transition from `Created` to `Cancelled` directly if the prizes were never deposited.
   Ticket buyers can still withdraw the fees spent.

### Protocol fees

The contract owner can set a protocol fee recipient and a protocol fee basis points (up to 25%) per raffle.

### Pricing options

Each raffle can have between 1 to5 pricing options. The rules are as follows:

1. The raffle's minimum entries must be divisible by the first pricing option's entries count.
2. The first pricing option must not have a price of 0.
3. Each pricing option after the first one must have a higher entries count than the previous one.
4. Each pricing option after the first one must have a higher **total price** than the previous one.
5. Each pricing option after the first one must not have a higher **price per entry** than the previous one.
6. Each pricing option's entries count must be divisible by the next pricing option's entries count.

### Misc. rules

1. Each raffle's lifespan must between 1 day to 7 days.
2. If the fee/prize token is an ERC-20, then it must be allowed by the contract owner (LooksRare's multi-sig).
3. There can be up to 200 prizes per raffle. Each ERC-721 prize counts as 1 even if they belong to the same collection.
   Each ERC-20 / ERC-1155 with the same token ID and multiple winners count as 1.
4. The maximum winners per raffle is 200.
