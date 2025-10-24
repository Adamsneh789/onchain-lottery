Onchain Lottery
The Onchain Lottery contract provides a fully decentralized, transparent, and tamper-proof lottery system built on the Stacks blockchain.
It allows participants to enter lottery rounds by staking STX or tokens, and winners are selected randomly on-chain using verifiable randomness derived from block hashes or commit-reveal schemes.

Features
Trustless lottery participation and random draws
Uses commit-reveal or block hash randomness for fairness
Round-based design with configurable ticket prices and durations
Automatic reward distribution to winners
Transparent entry records and event logging
DAO or admin-controlled round management

Technical Overview
Language: Clarity
Purpose: Enable decentralized and transparent on-chain raffles
Use Cases: Gaming, NFT raffles, DAO community rewards, DeFi promotions

Example Flow
Step 1: Admin creates a new round
(contract-call? .onchain-lottery create-round u1000000 u15000)
Step 2: Players join by buying tickets
(contract-call? .onchain-lottery enter u1 u3) ;; 3 tickets
Step 3: Once end-block passes, admin or anyone calls
(contract-call? .onchain-lottery draw-winner u1)
Step 4: Winner calls claim-prize to receive rewards
(contract-call? .onchain-lottery claim-prize u1)
