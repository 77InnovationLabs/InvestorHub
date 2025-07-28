## Document Control

- **Version:** 1.0
- **Authors:** InvestorHub Development Team
- **Date:** June 29, 2025
- **Approval:** Pending
- **Change History:**
  - Version 1.0: Initial draft created for InvestorHub v1.0 architecture (June 29, 2025)

## Table of Contents

1. Executive Summary
2. Solution Architecture Overview
3. Business Case
4. Requirements Summary
5. High-Level Solution Design
6. Detailed Solution Architecture
7. Integration Architecture
8. Data Architecture
9. Security Architecture
10. Infrastructure Requirements
11. Non-Functional Requirements
12. Transition and Implementation Strategy
13. Risks and Mitigations
14. Appendices
15. Glossary

## 1. Executive Summary

InvestorHub is a web application designed to simplify cryptocurrency investing for beginners by providing seamless access to DeFi liquidity pools across multiple blockchains. The platform addresses barriers such as complex terminology, hidden fees, and DeFi inaccessibility through a user-friendly interface, gamified education, and automated processes. The architecture leverages Chainlink’s suite of tools (CCIP, Automation, Data Feeds, Functions) for cross-chain interoperability, secure data integration, and automated token management, ensuring a scalable, secure, and non-custodial solution. This document outlines the technical architecture, integration strategies, and requirements to support InvestorHub’s vision of becoming the most trusted platform for novice crypto investors.

## 2. Solution Architecture Overview

InvestorHub’s architecture is a modular, non-custodial system built to simplify DeFi investments. Key components include:

- **Frontend**: A React.js-based interface with Tailwind CSS, providing a responsive, mobile-first user experience with gamified learning and investment flows.
- **Backend**: A Node.js/Express API server handling user management, data caching, and blockchain interactions, with MongoDB for user data and Redis for caching.
- **Blockchain Layer**: Smart contracts on Ethereum and Avalanche, integrated with Chainlink CCIP for cross-chain transactions, Chainlink Automation for fee conversions, and TheGraph for token/pool data.
- **Security**: Non-custodial wallet integration (Privy.io), end-to-end encryption, and compliance with GDPR/CCPA.
  The system connects users to curated liquidity pools (e.g., Uniswap V3) with one-click investments, abstracting complexities like token swaps and gas fees.

## 3. Business Case

InvestorHub addresses the following problems for new crypto investors:

- **Complex DeFi Processes**: Simplifies multi-step processes (e.g., token swaps, bridging, pool deposits) into a single transaction using Chainlink CCIP.
- **Cognitive Overload**: Reduces barriers with gamified education, contextual explanations, and a simplified UI/UX.
- **Fee Transparency**: Automates gas fee calculations and reserves funds for withdrawals, displaying costs clearly.
- **Limited Access to Opportunities**: Aggregates investment opportunities across chains (e.g., Avalanche, Ethereum) using Chainlink CCIP, enabling users to invest with any dex-tradable token.
- **Security Concerns**: Ensures user control via non-custodial wallets and secure integrations.
  The platform targets 100,000 active users and $250 million in transaction volume in the first year, tapping into a $15 billion serviceable addressable market for DeFi solutions.

## 4. Requirements Summary

### Business Requirements

- Enable one-click investments in curated liquidity pools (e.g., LINK/USDC, ETH/USDC).
- Provide gamified learning modules with IHUB token rewards (post-MVP).
- Ensure transparent fee management, including gas cost reservation.
- Support cross-chain investments via Chainlink CCIP.
- Achieve 80% user completion rate for educational modules and 70% retention after 6 months.

### Technical Requirements

- **Frontend**: React.js with Tailwind CSS, Privy.io wallet integration.
- **Backend**: Node.js/Express, MongoDB for user data, Redis for caching, TheGraph for token/pool data.
- **Blockchain**: Smart contracts on Ethereum/Avalanche, Chainlink CCIP, Automation, Data Feeds, and Functions.
- **Performance**: <2s page load, <500ms API responses, 99.9% uptime, support for 1,000 concurrent users.
- **Security**: End-to-end encryption, 2FA, KYC/AML compliance, smart contract audits.

## 5. High-Level Solution Design

![High-Level Design](https://github.com/77InnovationLabs/StakingAggregator/blob/main/staking-aggregator-hld.png)

The architecture consists of:

- **Client Layer**: Browser-based React.js app with PWA capabilities, integrated with Privy.io for wallet authentication.
- **Application Layer**: Node.js/Express server handling API requests, user management, and data caching (Redis).
- **Data Layer**: MongoDB for user profiles, Redis for token/pool data, and TheGraph for blockchain queries.
- **Blockchain Layer**: Diamond proxy smart contracts on Ethereum/Avalanche, leveraging Chainlink CCIP for cross-chain operations, Automation for IHUB buybacks, and Data Feeds for price conversions.
- **External Integrations**: Uniswap V3 for liquidity pools, Onfido for KYC/AML, and Chainlink Functions for off-chain swap payloads.

## 6. Detailed Solution Architecture

### System Modules

1. **User Management**:
   - Handles registration, KYC/AML (Onfido), and 2FA via Privy.io.
   - Stores user profiles in MongoDB with GDPR/CCPA-compliant encryption.
2. **Educational Module**:
   - Gamified learning path with interactive tutorials, quizzes, and IHUB rewards (post-MVP).
   - Contextual glossary and investment simulator using cached token data.
3. **Investment Module**:
   - Curates whitelisted liquidity pools (Uniswap V3) with APY, TVL, and risk scores.
   - Executes one-click investments via smart contracts, handling token swaps and cross-chain transfers (Chainlink CCIP).
4. **Portfolio Management**:
   - Displays real-time pool performance, interest earned, and impermanent loss risks.
   - Supports tax export and custom watchlists.
5. **Fee Management**:
   - Automates gas fee calculations (Avalanche APIs) and reserves funds for withdrawals.
   - Uses Chainlink Automation for IHUB buybacks based on USD thresholds.
6. **Token Management**:
   - Manages IHUB tokens (post-MVP) with smart contracts for minting and peg maintenance (USDC/DAI).
   - Integrates Chainlink Functions for off-chain swap payload creation.

### Architectural Diagram

(TBD: Detailed diagram to be added, showing client, server, blockchain, and Chainlink interactions.)

## 7. Integration Architecture

### External Integrations

- **Uniswap V3**: Provides liquidity pool access via smart contracts (StartUniswapV3PositionFacet, DecreaseLiquidityFacet).
- **Chainlink CCIP**: Enables cross-chain investments (e.g., wBTC on Avalanche to LINK/USDT on Ethereum) via CCIPSendFacet and CCIPReceiveFacet.
- **Chainlink Automation**: Triggers IHUB buybacks (VaultAutomation.sol) based on fee thresholds.
- **Chainlink Data Feeds**: Converts LINK fees to USDC (DataFeedsFacet.sol).
- **Chainlink Functions**: Generates off-chain swap payloads for IHUB conversions (IHUBFunctions.sol).
- **TheGraph**: Queries token/pool data (prices, APY, TVL) with 5-minute cache refresh (Redis).
- **Privy.io**: Handles wallet authentication and social logins.
- **Onfido**: Manages KYC/AML compliance.

### Data Flows

1. **Investment Flow**:
   - User selects pool and token (e.g., wETH).
   - Backend queries TheGraph for pool data, caches in Redis.
   - Smart contracts execute swaps (StartSwapFacet) and deposits (StartUniswapV3PositionFacet), using CCIP for cross-chain transfers.
2. **Fee Management**:
   - Gas fees calculated via Avalanche APIs, reserved in escrow.
   - Chainlink Automation triggers IHUB buybacks when fees reach USD threshold.
3. **Data Retrieval**:
   - Daemon service queries TheGraph every 5 minutes, caches in Redis.
   - Frontend retrieves cached data for low-latency display.

## 8. Data Architecture

### Data Model

- **MongoDB**:
  - User Collection: Stores user profiles (email, preferences, KYC status).
  - Transaction Collection: Logs investment/withdrawal details.
- **Redis**:
  - Caches token/pool data (prices, APY, TVL) with 5-minute TTL.
- **TheGraph**:
  - Subgraphs for whitelisted tokens/pools, providing price, volume, and APY data.

### Data Migration

- Initial user data migration from legacy systems (if any) via MongoDB import scripts.
- Token/pool data seeded from TheGraph and cached in Redis.

### Reporting

- Portfolio dashboard with real-time analytics (APY, holdings, impermanent loss).
- Exportable transaction logs for tax compliance.

## 9. Security Architecture

- **Authentication**: Privy.io for wallet-based and social logins, 2FA support.
- **Encryption**: End-to-end encryption for API communications, HTTPS with HSTS.
- **Smart Contracts**: Audited contracts (Diamond structure, Chainlink facets) with multi-signature wallets for asset management.
- **Compliance**: GDPR/CCPA for data privacy, Onfido for KYC/AML.
- **Protection**: Rate limiting, DDoS mitigation, and defenses against XSS, CSRF, and SQLi.
- **Chainlink Security**: CCIP for secure cross-chain transfers, Automation for reliable triggers.

## 10. Infrastructure Requirements

### Hardware

- Cloud-hosted servers on Heroku for backend and frontend.
- Redis cluster for caching, MongoDB Atlas for database hosting.

### Software

- **Frontend**: React.js, Tailwind CSS, Ether.js for blockchain interactions.
- **Backend**: Node.js/Express, NestJS, MongoDB, Redis.
- **Blockchain**: Solidity contracts on Ethereum/Avalanche, Foundry for testing.
- **DevOps**: Docker for containerization, Heroku for deployment.

### Network

- Load balancers for API traffic distribution.
- CDN for static assets to reduce latency.

## 11. Non-Functional Requirements

- **Performance**: Page load <2s, API response <500ms, token data refresh every 5 minutes.
- **Scalability**: Support 1,000 concurrent users, scalable via Heroku dynos and Redis clustering.
- **Reliability**: 99.9% uptime, ensured by Heroku and Chainlink’s hyper-reliable network.
- **Availability**: Multi-region deployment for failover, TheGraph fallback to CoinGecko/Space & Time.
- **Accessibility**: WCAG 2.1 AA compliance for inclusive design.

## 12. Transition and Implementation Strategy

### Phases

- **MVP (Q3 2025)**:
  - Core account functionality, KYC/AML, basic education modules.
  - Uniswap V3 integration for top 3 pools (LINK/USDC, ETH/USDC, DAI/USDT).
  - Chainlink CCIP for cross-chain investments, Automation for fee buybacks.
- **Post-MVP (Q4 2025)**:
  - Full gamification system, investment simulator, portfolio analytics.
  - Expanded pool whitelist using AI-driven curation.
- **V1 (Q1 2026)**:
  - IHUB token launch, staking, and additional DeFi options.
  - Mobile app and social features (leaderboards, community).

### Timeline

- Q2 2025: Smart contract development and audits.
- Q3 2025: MVP launch with core features.
- Q4 2025: Post-MVP feature rollout.
- Q1 2026: V1 release with mobile app.

## 13. Risks and Mitigations

### Risks

- **Market**: Crypto volatility, impermanent loss, competitive landscape.
- **Technical**: TheGraph downtime, smart contract vulnerabilities, gas fee spikes.
- **Operational**: Liquidity constraints, customer support scaling.
- **Regulatory**: Evolving DeFi regulations, token classification risks.

### Mitigations

- **Market**: Curate low-risk pools, educate users on impermanent loss.
- **Technical**: Use CoinGecko/Space & Time as TheGraph fallback, conduct audits, implement gas fee reserves.
- **Operational**: Dynamic fee adjustments, tiered support system.
- **Regulatory**: Legal reviews, phased jurisdictional rollout.

## 14. Appendices

- **User Journey Maps**: Included in README.md (Section 5).
- **Wireframes & Mockups**: TBD.
- **Token Economics**: TBD.
- **Fee Structure**: Tentative 0.1% of invested amount, TBD.
- **Technical Diagrams**: TBD.

## 15. Glossary

- **CCIP**: Chainlink Cross-Chain Interoperability Protocol.
- **IHUB**: InvestorHub’s utility token, pegged to USDC/DAI (post-MVP).
- **TheGraph**: Decentralized protocol for querying blockchain data.
- **Privy.io**: Wallet authentication platform.
- **Uniswap V3**: Decentralized exchange for liquidity pools.
- **Impermanent Loss**: Potential loss in liquidity pools due to price divergence.
