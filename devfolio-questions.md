# Devfolio project questions

## The problem it solves

**InvestorHub** addresses the significant barriers faced by new cryptocurrency investors, particularly in navigating decentralized finance (DeFi) liquidity pools.

The key problems it solves:

- _Complex Terminology and Concepts_: Newcomers are often overwhelmed by crypto jargon (e.g., "gas fees," "impermanent loss") and intricate DeFi mechanisms, resulting in a high cognitive load. InvestorHub simplifies these through clear, jargon-free explanations, interactive tutorials, and a contextual glossary.
  Hidden Costs and Fees: Gas fees and other transaction costs are often unclear, deterring beginners. The platform provides transparent fee breakdowns, automated gas fee management, and reserves funds for withdrawals to ensure cost clarity.
- _Difficulty Accessing DeFi Opportunities_: Liquidity pools and other DeFi investments are intimidating due to their complexity. InvestorHub provides one-click access to curated, secure liquidity pools, offering clear risk and reward information.
- _Lack of Confidence and Education_: Beginners often fear scams, volatility, and losses due to a lack of experience. The platform builds confidence through gamified learning, earning IHUB tokens, and an investment simulator for risk-free practice.
- _Security and Trust Concerns_: Novice investors worry about platform security and reliability. InvestorHub ensures trust with robust security measures and a non-custodial model where users retain control of their funds.

## Challenges I ran into

Developing InvestorHub v1.0, a cross-chain DeFi platform for novice investors, presented several technical challenges, particularly in integrating Avalanche and other blockchains with Chainlink tools.
Below are the key challenges we encountered.

1. Multi-Chain Integration : Integrating multiple blockchains (Avalanche, Ethereum, Base Sepolia) for seamless cross-chain investments was complex due to differing network characteristics (e.g., Avalanche’s high throughput vs. Ethereum’s higher gas costs) and ensuring interoperability via Chainlink CCIP.

   - _Lessons learned_ : Implemented extensive testing with Foundry to simulate cross-chain scenarios and added monitoring for CCIP performance to mitigate disruptions.

2. Cross-Chain Investment Architecture (Consolidated with Multi-Chain Integration) : designing a robust cross-chain investment architecture to abstract complex processes (e.g., token swaps, bridging, pool deposits) into a single transaction was difficult, especially ensuring compatibility between Avalanche and Ethereum.

   - _Lessons learned_ : Used Chainlink Data Feeds for accurate fee conversions and implemented error-handling mechanisms in smart contracts (e.g., StartUniswapV3PositionFacet) to rollback failed transactions.

3. Modularizing Architecture Using the Diamond Proxy: implementing the Diamond proxy pattern to modularize smart contracts was complex due to the need for upgradability and gas efficiency while maintaining security.

   - _Lessons learned_ : Used Foundry for rigorous testing and conducted initial smart contract audits to validate the Diamond structure’s integrity.

4. Input Token: Value of the Token in the Investor’s Portfolio: accurately handling the value of input tokens (e.g., LINK, wETH, wBTC) in users’ portfolios across chains was challenging due to real-time price volatility and cross-chain data consistency.

   - _Lessons learned_ : Implemented Redis caching with a 5-minute refresh rate and fallback to CoinGecko/Space & Time to ensure data reliability.

5. Implementation of the Abstraction of the Investment Operation : abstracting complex investment operations (e.g., token swaps, cross-chain bridging, pool deposits) into a single, user-friendly transaction was technically demanding.

   - _Lessons learned_ : Developed guided UX flows with educational pop-ups and tested the abstraction layer under high-load scenarios to ensure reliability.

6. Fetch of Data from TheGraph : fetching real-time token and pool data (prices, APY, TVL) from TheGraph was challenging due to potential API downtime and query optimization needs.

   - _Lessons learned_ : Implemented failover to CoinGecko/Space & Time and optimized query structures to reduce latency, with monitoring for daemon health.

7. Implementing All Smart Contracts Without Storage (Immutable and Constant): designing smart contracts to be immutable and constant (no storage) was difficult to balance with functionality and upgradability needs.

   - _Lessons learned_ : Used the Diamond proxy to delegate state to external systems and conducted audits to ensure immutability didn’t compromise functionality.

8. Backend and API Architecture : building a scalable backend and API architecture to handle cross-chain data and user interactions was complex due to high concurrency and real-time requirements.

   - _Lessons learned_ : Deployed on Heroku with load balancers and optimized Redis caching for low latency, with monitoring for API health.

9. Multi-Chain Integration in the Frontend: integrating multi-chain functionality into the React.js frontend was challenging due to wallet compatibility and real-time data updates across Avalanche, Ethereum, and Base Sepolia.

   - _Lessons learned_ : Used Ether.js for blockchain interactions, implemented mobile-first design with Tailwind CSS, and tested cross-chain UX with novice personas.

## Tracks applied

### Cross-Chain Solutions

_How does this project fit within the track?_

Fit with Cross-Chain Solutions Track:

- _Chainlink CCIP as Core Enabler_: powers cross-chain investments with one-click transactions, addressing liquidity fragmentation.
- _User-Friendly Cross-Chain DeFi_: targets novices with a simplified UI, gamified education, and one-click investments, making cross-chain DeFi accessible and intuitive.
- Comprehensive Chainlink Integration: utilizes CCIP, Automation, Data Feeds (for price conversions), Functions (for off-chain payloads), and CCT (for token standardization) to create a robust cross-chain ecosystem.
- _Non-Custodial Security_: Model with Privy.io and audited smart contracts ensures secure cross-chain transfers.
- _Scalability and Market Fit_: aggregates opportunities across chains (Avalanche, Ethereum, Base Sepolia), targeting a $15B DeFi market.

### Avalanche Track

_How does this project fit within the track?_

Fit with Cross-Chain Solutions Track (Avalanche Context)

- _Avalanche as Cross-Chain Hub for low-cost, high-speed transactions_ : enabling cross-chain investments (e.g., wBTC on Avalanche to LINK/USDT on Ethereum) via Chainlink CCIP.
- _User-Friendly DeFi on Avalanche_ : simplifies Avalanche-based DeFi for novices with one-click investments and gamified education.
- _Chainlink Tools on Avalanche_ : integrates CCIP (cross-chain transfers), Automation (IHUB buybacks), Data Feeds (price conversions), and Functions (off-chain payloads) on Avalanche.
- _Non-Custodial Security model with Privy.io_ : audited smart contracts on Avalanche ensures secure cross-chain operations.
- _Liquidity Fragmentation Solution_ aggregates cross-chain pools from Avalanche, turning fragmentation into opportunity.

### Onchain Finance

_How does this project fit within the track?_

Fit with Onchain Finance Track

- Simplified DeFi Access : enables one-click liquidity pool investments with gamified education, reducing DeFi complexity for beginners.
- Non-Custodial Model : uses Privy.io and audited smart contracts for trustless onchain transactions.
- Transparent Fee Management : automates gas fee calculations and reserves using Avalanche APIs and Chainlink Data Feeds, displaying costs clearly.
- Chainlink Onchain Tools : integrates CCIP (cross-chain investments), Automation (IHUB buybacks), Data Feeds (pricing), and Functions (swap payloads) for efficient onchain operations.
- Scalable Ecosystem : targets a $15B DeFi market with a Diamond proxy and plans for IHUB token and new protocols.

## Technologies used

- Solidity
- MongoDB
- Chainlink

## Platforms

- [x] web
