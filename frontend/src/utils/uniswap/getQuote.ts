import { ConnectedWallet } from '@privy-io/react-auth'
import Quoter from '../../assets/abi/ABI_Quoter.json'
import { ethers } from 'ethers'
import { PartialToken, Token } from '../../interfaces/token'
import { fromReadableAmount, toReadableAmount } from '../convertions'
import { NETWORKS_CONFIGS, ALL_FEE_TIERS } from '../constants'

const AMOUNT_1 = 1;

export async function getUSDPriceQuote(wallet: ConnectedWallet, tokenIn: PartialToken, fee: number): Promise<any> {
  const ethersProvider = new ethers.BrowserProvider(await wallet.getEthereumProvider());
  console.log('wallet.chainId', wallet.chainId);
  const quoterContract = new ethers.Contract(
    NETWORKS_CONFIGS[wallet.chainId].quoterContract,
    Quoter.abi,
    ethersProvider
  )

  const usdToken = NETWORKS_CONFIGS[wallet.chainId].usdToken;
  const amountIn = fromReadableAmount(
    AMOUNT_1,
    Number(tokenIn.decimals) ?? 18
  ).toString();

  console.log('getUSDPriceQuote: quoterContract', quoterContract);
  console.log('getUSDPriceQuote: tokenIn', tokenIn);
  console.log('getUSDPriceQuote: USD Token', NETWORKS_CONFIGS[wallet.chainId].usdToken);
  console.log('getUSDPriceQuote: fee', fee);
  console.log('getUSDPriceQuote: amountIn', fromReadableAmount(
    AMOUNT_1,
    Number(tokenIn.decimals) ?? 18
  ).toString());

  const path = ethers.solidityPacked(
    ['address', 'uint24', 'address'],
    [tokenIn.address, BigInt(fee), usdToken.address]
  );

  const quotedAmountOut = await quoterContract.quoteExactInput.staticCall(
    path,
    amountIn
  );

  console.log('getUSDPriceQuote: quotedAmountOut', quotedAmountOut);
  return toReadableAmount(quotedAmountOut[0], Number(usdToken.decimals) ?? 18);
}

export async function getTokenPriceQuote(wallet: ConnectedWallet, tokenIn: PartialToken, tokenOut: Token, fee: number, amountIn: number): Promise<any> {
  const ethersProvider = new ethers.BrowserProvider(await wallet.getEthereumProvider());
  console.log('wallet.chainId', wallet.chainId);
  const quoterContract = new ethers.Contract(
    NETWORKS_CONFIGS[wallet.chainId].quoterContract,
    Quoter.abi,
    ethersProvider
  );

  const amountInFormatted = fromReadableAmount(
    amountIn,
    Number(tokenIn.decimals) ?? 18
  ).toString();

  console.log('getTokenPriceQuote: quoterContract', quoterContract);
  console.log('getTokenPriceQuote: tokenIn', tokenIn);
  console.log('getTokenPriceQuote: tokenOut', tokenOut);
  console.log('getTokenPriceQuote: fee', fee);
  console.log('getTokenPriceQuote: amountIn', amountInFormatted);

  const path = ethers.solidityPacked(
    ['address', 'uint24', 'address'],
    [tokenIn.address, BigInt(fee), tokenOut.address]
  )

  const quotedAmountOut = await quoterContract.quoteExactInput.staticCall(
    path,
    amountInFormatted
  );

  console.log('getTokenPriceQuote:quotedAmountOut', quotedAmountOut);

  // Handle the Proxy result - the first element is the amount
  const amountOut = quotedAmountOut[0];
  console.log('getTokenPriceQuote:amountOut', amountOut);

  return {amountOut: toReadableAmount(amountOut, Number(tokenOut.decimals) ?? 18), path: path};
}

export async function getBestUSDPriceQuote(wallet: ConnectedWallet, tokenIn: PartialToken): Promise<{ quote: any, fee: number }> {
  
  if(tokenIn.address === NETWORKS_CONFIGS[wallet.chainId].usdToken.address) {
    return { quote: "1", fee: 0 }; //TODO: get the real price for USD
  }

  const ethersProvider = new ethers.BrowserProvider(await wallet.getEthereumProvider());
  const quoterContract = new ethers.Contract(
    NETWORKS_CONFIGS[wallet.chainId].quoterContract,
    Quoter.abi,
    ethersProvider
  );

  const usdToken = NETWORKS_CONFIGS[wallet.chainId].usdToken;
  const amountIn = fromReadableAmount(
    AMOUNT_1,
    Number(tokenIn.decimals) ?? 18
  ).toString();

  console.log('getBestUSDPriceQuote: trying all fee tiers for token', tokenIn.symbol);

  let bestQuote = null;
  let bestFee = 0;
  let hasValidQuote = false;

  for (const fee of ALL_FEE_TIERS) {
    try {
      console.log(`Trying fee tier: ${fee}`);
      
      const path = ethers.solidityPacked(
        ['address', 'uint24', 'address'],
        [tokenIn.address, BigInt(fee), usdToken.address]
      );

      const quotedAmountOut = await quoterContract.quoteExactInput.staticCall(
        path,
        amountIn
      );

      const readableQuote = toReadableAmount(quotedAmountOut[0], Number(usdToken.decimals) ?? 18);
      console.log(`Fee ${fee}: quote = ${readableQuote}`);

      if (!bestQuote || Number(readableQuote) > Number(bestQuote)) {
        bestQuote = readableQuote;
        bestFee = fee;
        hasValidQuote = true;
      }
    } catch (error) {
      console.log(`Fee tier ${fee} failed:`, error);
      // Continue to next fee tier
    }
  }

  if (!hasValidQuote) {
    throw new Error(`No valid quotes found for token ${tokenIn.symbol} to USD across all fee tiers`);
  }

  console.log(`Best quote: ${bestQuote} at fee tier ${bestFee}`);
  return { quote: bestQuote, fee: bestFee };
}

export async function getBestTokenPriceQuote(wallet: ConnectedWallet, tokenIn: Token, tokenOut: Token): Promise<{ quote: any, fee: number }> {
  const ethersProvider = new ethers.BrowserProvider(await wallet.getEthereumProvider());
  const quoterContract = new ethers.Contract(
    NETWORKS_CONFIGS[wallet.chainId].quoterContract,
    Quoter.abi,
    ethersProvider
  );

  const amountIn = fromReadableAmount(
    AMOUNT_1,
    Number(tokenIn.decimals) ?? 18
  ).toString();

  console.log('getBestTokenPriceQuote: trying all fee tiers', tokenIn.symbol, '→', tokenOut.symbol);

  let bestQuote = null;
  let bestFee = 0;
  let hasValidQuote = false;

  for (const fee of ALL_FEE_TIERS) {
    try {
      console.log(`Trying fee tier: ${fee}`);
      
      const path = ethers.solidityPacked(
        ['address', 'uint24', 'address'],
        [tokenIn.address, BigInt(fee), tokenOut.address]
      );

      const quotedAmountOut = await quoterContract.quoteExactInput.staticCall(
        path,
        amountIn
      );

      const readableQuote = toReadableAmount(quotedAmountOut[0], Number(tokenOut.decimals) ?? 18);
      console.log(`Fee ${fee}: quote = ${readableQuote}`);

      if (!bestQuote || Number(readableQuote) > Number(bestQuote)) {
        bestQuote = readableQuote;
        bestFee = fee;
        hasValidQuote = true;
      }
    } catch (error) {
      console.log(`Fee tier ${fee} failed:`, error);
      // Continue to next fee tier
    }
  }

  if (!hasValidQuote) {
    throw new Error(`No valid quotes found for ${tokenIn.symbol} to ${tokenOut.symbol} across all fee tiers`);
  }

  console.log(`Best quote: ${bestQuote} at fee tier ${bestFee}`);
  return { quote: bestQuote, fee: bestFee };
}