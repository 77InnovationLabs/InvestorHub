# Quote API

This module provides Uniswap V3 price quote functionality for getting the best prices across all fee tiers.

## Endpoints

### 1. Get Best USD Price Quote

**POST** `/quote/usd-price`

Returns the best USD price quote for a given token across all Uniswap V3 fee tiers (0.01%, 0.05%, 0.3%, 1%).

#### Request Body

```json
{
  "network": "eip155:11155111",
  "tokenAddress": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  "tokenDecimals": 18,
  "tokenSymbol": "LINK"
}
```

#### Response

```json
{
  "quote": "1.23456789",
  "fee": 3000,
  "tokenAddress": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  "tokenSymbol": "LINK",
  "network": "eip155:11155111",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

### 2. Get Best Token Price Quote

**POST** `/quote/token-price`

Returns the best price quote for swapping between two tokens across all Uniswap V3 fee tiers.

#### Request Body

```json
{
  "network": "eip155:11155111",
  "tokenInAddress": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  "tokenInDecimals": 18,
  "tokenInSymbol": "LINK",
  "tokenOutAddress": "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
  "tokenOutDecimals": 18,
  "tokenOutSymbol": "WETH"
}
```

#### Response

```json
{
  "quote": "0.00012345",
  "fee": 3000,
  "tokenInAddress": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  "tokenInSymbol": "LINK",
  "tokenOutAddress": "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
  "tokenOutSymbol": "WETH",
  "network": "eip155:11155111",
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Supported Networks

- `eip155:11155111` - Sepolia (Ethereum testnet)
- `eip155:84532` - Base Sepolia (Base testnet)
- `eip155:1` - Ethereum mainnet
- `eip155:8453` - Base mainnet

## Fee Tiers

The API tries all Uniswap V3 fee tiers:
- 100 (0.01%)
- 500 (0.05%)
- 3000 (0.3%)
- 10000 (1%)

### 3. Get Best Route

**POST** `/quote/best-route`

Returns the best route for swapping between two tokens using Uniswap Smart Order Router, including multi-hop routes and gas estimates.

#### Request Body

```json
{
  "network": "eip155:11155111",
  "tokenInAddress": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  "tokenInDecimals": 18,
  "tokenInSymbol": "LINK",
  "tokenOutAddress": "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
  "tokenOutDecimals": 18,
  "tokenOutSymbol": "WETH",
  "amountIn": "1000000000000000000",
  "tradeType": "EXACT_INPUT",
  "recipient": "0x742d35Cc6634C0532925a3b8D4C9db96C4b4d8b6",
  "slippageTolerance": 50
}
```

#### Response

```json
{
  "amountIn": "1000000000000000000",
  "amountOut": "999500000000000000",
  "gasCost": "500000",
  "tokenInAddress": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
  "tokenInSymbol": "LINK",
  "tokenOutAddress": "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
  "tokenOutSymbol": "WETH",
  "network": "eip155:11155111",
  "tradeType": "EXACT_INPUT",
  "route": [
    {
      "tokenIn": "0x779877A7B0D9E8603169DdbD7836e478b4624789",
      "tokenInSymbol": "LINK",
      "tokenOut": "0xfFf9976782d46CC05630D1f6eBAb18b2324d6B14",
      "tokenOutSymbol": "WETH",
      "fee": 3000,
      "poolAddress": "0x1234567890abcdef..."
    }
  ],
  "timestamp": "2024-01-15T10:30:00.000Z",
  "methodParameters": {
    "calldata": "0x1234567890abcdef...",
    "value": "0",
    "to": "0xE592427A0AEce92De3Edee1F18E0157C05861564"
  }
}
```

## Error Responses

- `400 Bad Request` - Invalid request parameters or unsupported network
- `404 Not Found` - No valid quotes found across all fee tiers

## Implementation Details

- Uses ethers.js for blockchain interactions
- Dynamically fetches quotes from Uniswap V3 Quoter contracts
- Returns the highest quote amount across all fee tiers
- Includes comprehensive logging for debugging
- Validates network support before attempting quotes
- **Best Route**: Uses Uniswap Smart Order Router for optimal routing across V2 and V3 pools 