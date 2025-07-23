import React, { useState, useEffect} from 'react';
import { ConnectedWallet, useWallets } from '@privy-io/react-auth';
import { useParams } from 'react-router-dom';
import { calculateTickValues } from '../utils/uniswap/getTickValues';
import { PoolData } from '../interfaces/pooldata';
import { getUSDPriceQuote, getTokenPriceQuote } from '../utils/uniswap/getQuote';
import { getTokenDetails, getTokenBalance } from '../utils/erc20/getTokenInformation';
import { PartialToken, Token } from '../interfaces/token';
import { startSwapAndWait } from '../utils/aggregator/investStartSwap';
import { StartSwapParams } from '../interfaces/startswapparams';
import { checkAndExecuteApprovalAndWait } from '../utils/erc20/executeapprovals';
import { fromReadableAmount } from '../utils/convertions';

const NewPositionV2: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const [poolData, setPoolData] = useState<PoolData | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [tickValues, setTickValues] = useState<any>(null);
    const [token0Price, setToken0Price] = useState<string | null>(null);
    const [token1Price, setToken1Price] = useState<string | null>(null);
    const [tokenAddress, setTokenAddress] = useState<string>('');
    const [customTokenDetails, setCustomTokenDetails] = useState<PartialToken | null>(null);
    const [customTokenBalance, setCustomTokenBalance] = useState<string | null>(null);
    const [customTokenUSDPrice, setCustomTokenUSDPrice] = useState<string | null>(null);
    const [investmentAmount, setInvestmentAmount] = useState<string>('');
    const [investmentQuotes, setInvestmentQuotes] = useState<{
        token0Quote?: string;
        token1Quote?: string;
        otherTokenQuote?: string;
    } | null>(null);
    const [loadingQuotes, setLoadingQuotes] = useState(false);
    const [loadingTokenInfo, setLoadingTokenInfo] = useState(false);
    const { wallets: privyWallets, ready } = useWallets();

    const fetchPoolById = async (): Promise<PoolData> => {
        try {
            const response = await fetch(`${import.meta.env.VITE_API_URL}/pools/${id}`, {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! status: ${response.status}`);
            }

            const data = await response.json();
            return data;
        } catch (error) {
            console.error('Error fetching pool by ID:', error);
            throw error;
        }
    }

    const getUSDPrice = async (connectedWallet: ConnectedWallet, token0: PartialToken, fee: number) => {
        const quoteResponse = await getUSDPriceQuote(connectedWallet, token0, fee);
        return quoteResponse;
    }

    const fetchCustomTokenInfo = async () => {
        if (!tokenAddress.trim() || !ready || privyWallets.length === 0) {
            return;
        }

        setLoadingTokenInfo(true);
        setError(null);

        try {
            // Fetch token details and balance in parallel
            const [tokenDetails, tokenBalance] = await Promise.all([
                getTokenDetails(privyWallets[0], tokenAddress.trim()),
                getTokenBalance(privyWallets[0], tokenAddress.trim())
            ]);

            setCustomTokenDetails(tokenDetails);
            setCustomTokenBalance(tokenBalance);

            // Get USD price for the custom token (using default fee tier 3000)
            try {
                const usdPrice = await getUSDPrice(privyWallets[0], tokenDetails, 3000);
                setCustomTokenUSDPrice(usdPrice);
            } catch (priceError) {
                console.warn('Could not fetch USD price for custom token:', priceError);
                setCustomTokenUSDPrice(null);
            }
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to fetch token information');
            console.error('Error fetching custom token info:', err);
            setCustomTokenDetails(null);
            setCustomTokenBalance(null);
            setCustomTokenUSDPrice(null);
        } finally {
            setLoadingTokenInfo(false);
        }
    };

    const handleTokenAddressSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        fetchCustomTokenInfo();
    };

    const investInPool = async () => {
        if (!tickValues || !investmentAmount.trim() || !customTokenDetails || !customTokenDetails.decimals || !poolData || !poolData.token1.decimals || !poolData.token0.decimals || !ready || privyWallets.length === 0) {
            return;
        }

        setLoadingQuotes(true);
        setError(null);

        try {
            const investmentValue = parseFloat(investmentAmount);
            const halfInvestment = investmentValue / 2;

            // Check if the typed token matches pool tokens
            const isToken0 = customTokenDetails.address.toLowerCase() === poolData.token0.address.toLowerCase();
            const isToken1 = customTokenDetails.address.toLowerCase() === poolData.token1.address.toLowerCase();

            let quotes: {
                token0Quote?: string;
                token1Quote?: string;
                otherTokenQuote?: string;
            } = {};

            if (isToken0 || isToken1) {

                // If typed token is one of the pool tokens
                const otherToken = isToken0 ? poolData.token1 : poolData.token0;
                
                // Convert pool token to match Token interface
                const otherTokenFormatted: Token = {
                    ...otherToken,
                    decimals: otherToken.decimals
                };
                
                // Get quote for typed token as input and other token as output
                const quote = await getTokenPriceQuote(
                    privyWallets[0], 
                    customTokenDetails, 
                    otherTokenFormatted, 
                    Number(poolData.feeTier),
                    halfInvestment
                );
                
                const path = quote.path;
                const amountOut = quote.amountOut;

                const startSwapParams: StartSwapParams = {
                    totalAmountIn: fromReadableAmount(Number(investmentAmount), Number(customTokenDetails.decimals)).toString(),
                    payload: {
                        path: path,
                        amountInForInputToken: fromReadableAmount(Number(halfInvestment), Number(customTokenDetails.decimals)).toString(),
                        deadline: "0",
                    },
                    stakePayload: {
                        token0: customTokenDetails.address,
                        token1: otherToken.address,
                        fee: Number(poolData.feeTier),
                        tickLower: tickValues.minTick,
                        tickUpper: tickValues.maxTick,
                        amount0Desired: fromReadableAmount(halfInvestment, Number(otherToken.decimals)).toString(),
                        amount1Desired: (BigInt(fromReadableAmount(Number(amountOut), Number(otherToken.decimals))) * BigInt(85) / BigInt(100)).toString(), // Slippage 15%
                        amount0Min: "0", // TODO: Add min amount out
                        amount1Min: "0", // TODO: Add min amount out
                        recipient: privyWallets[0].address,
                        deadline: (Math.floor(Date.now() / 1000) + 900).toString()
                    }
                };

                await checkAndExecuteApprovalAndWait(
                    customTokenDetails.address,
                    fromReadableAmount(Number(investmentAmount), Number(customTokenDetails.decimals)).toString(),
                    privyWallets[0]
                );

                const tx = await startSwapAndWait(privyWallets[0], startSwapParams);
                console.log('Swap transaction:', tx);

            } else {
                // If typed token is not one of the pool tokens
                // Convert pool tokens to match Token interface
                const token0Formatted: Token = {
                    ...poolData.token0,
                    decimals: poolData.token0.decimals
                };
                const token1Formatted: Token = {
                    ...poolData.token1,
                    decimals: poolData.token1.decimals
                };
                
                // Get quote for typed token as input and token0 as output
                const quoteToken0 = await getTokenPriceQuote(
                    privyWallets[0], 
                    customTokenDetails, 
                    token0Formatted, 
                    Number(poolData.feeTier),
                    halfInvestment
                );
                
                // Get quote for typed token as input and token1 as output
                const quoteToken1 = await getTokenPriceQuote(
                    privyWallets[0], 
                    customTokenDetails, 
                    token1Formatted, 
                    Number(poolData.feeTier),
                    halfInvestment
                );
                
                quotes.token0Quote = quoteToken0;
                quotes.token1Quote = quoteToken1;
                console.log(`Quote for ${customTokenDetails.symbol} to ${poolData.token0.symbol}:`, quoteToken0);
                console.log(`Quote for ${customTokenDetails.symbol} to ${poolData.token1.symbol}:`, quoteToken1);
                
            }

            setInvestmentQuotes(quotes);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to calculate investment quotes');
            console.error('Error calculating investment quotes:', err);
            setInvestmentQuotes(null);
        } finally {
            setLoadingQuotes(false);
        }
    };

    const handleInvestmentSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        investInPool();
    };

    useEffect(() => {
        const loadPoolData = async () => {
            setLoading(true);
            setError(null);

            try {
                const data = await fetchPoolById();
                setPoolData(data);
                console.log('Pool data loaded:', data);
                console.log('Wallets:', privyWallets);
                console.log('Ready:', ready);
                if(ready) {
                    const provider = await privyWallets[0].getEthereumProvider();
                    const tickValuesData = await calculateTickValues(provider, data.address);
                    setTickValues(tickValuesData);
                    console.log('Tick values:', tickValuesData);
                    const token0PriceData = await getUSDPrice(privyWallets[0], data.token0, Number(data.feeTier));
                    const token1PriceData = await getUSDPrice(privyWallets[0], data.token1, Number(data.feeTier));
                    setToken0Price(token0PriceData);
                    setToken1Price(token1PriceData);
                    console.log('Token0 price:', token0PriceData);
                    console.log('Token1 price:', token1PriceData);
                }
            } catch (err) {
                setError(err instanceof Error ? err.message : 'Failed to fetch pool data');
                console.error('Error loading pool data:', err);
            } finally {
                setLoading(false);
            }
        };

        loadPoolData();
    }, [id, ready]);
    
    return (
        <div>
            <h1>New Position V2</h1>
            
            {loading && <p>Loading pool data...</p>}
            
            {error && (
                <div style={{ color: 'red', margin: '10px 0' }}>
                    Error: {error}
                </div>
            )}
            
            {poolData && (
                <div>
                    <h2>Pool Information</h2>
                    
                    <div style={{ border: '1px solid #ccc', margin: '10px 0', padding: '10px' }}>
                        <h3>Pool Details</h3>
                        <p><strong>Pool ID:</strong> {poolData._id}</p>
                        <p><strong>Pool Address:</strong> {poolData.address}</p>
                        <p><strong>Fee Tier:</strong> {poolData.feeTier}</p>
                        <p><strong>Token Pair:</strong> {poolData.token0.symbol}/{poolData.token1.symbol}</p>
                        <p><strong>Token0:</strong> {poolData.token0.name} ({poolData.token0.symbol}) - {poolData.token0.decimals} decimals</p>
                        <p><strong>Token1:</strong> {poolData.token1.name} ({poolData.token1.symbol}) - {poolData.token1.decimals} decimals</p>
                        <p><strong>Created:</strong> {new Date(parseInt(poolData.createdAtTimestamp) * 1000).toLocaleString()}</p>
                        
                        {poolData.poolDayData.length > 0 && (
                            <div>
                                <h4>Recent Day Data:</h4>
                                {poolData.poolDayData.slice(0, 3).map((dayData, dayIndex) => (
                                    <div key={dayIndex} style={{ marginLeft: '20px' }}>
                                        <p><strong>Date:</strong> {new Date(parseInt(dayData.date) * 1000).toLocaleDateString()}</p>
                                        <p><strong>TVL:</strong> ${parseFloat(dayData.tvlUSD).toLocaleString()}</p>
                                        <p><strong>Volume:</strong> ${parseFloat(dayData.volumeUSD).toLocaleString()}</p>
                                        <p><strong>Fees:</strong> ${parseFloat(dayData.feesUSD).toLocaleString()}</p>
                                        <p><strong>APR:</strong> {dayData.apr24h}%</p>
                                    </div>
                                ))}
                            </div>
                        )}
                    </div>

                    {/* Custom Token Input Section */}
                    <div style={{ border: '1px solid #ccc', margin: '10px 0', padding: '10px' }}>
                        <h3>Custom Token Information</h3>
                        <form onSubmit={handleTokenAddressSubmit} style={{ marginBottom: '10px' }}>
                            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                                <input
                                    type="text"
                                    value={tokenAddress}
                                    onChange={(e) => setTokenAddress(e.target.value)}
                                    placeholder="Enter token address (0x...)"
                                    style={{ 
                                        flex: 1, 
                                        padding: '8px', 
                                        borderRadius: '4px', 
                                        border: '1px solid #ccc' 
                                    }}
                                />
                                <button 
                                    type="submit" 
                                    disabled={!tokenAddress.trim() || !ready || loadingTokenInfo}
                                    style={{ 
                                        padding: '8px 16px', 
                                        borderRadius: '4px', 
                                        border: 'none', 
                                        backgroundColor: '#007bff', 
                                        color: 'white', 
                                        cursor: 'pointer' 
                                    }}
                                >
                                    {loadingTokenInfo ? 'Loading...' : 'Get Token Info'}
                                </button>
                            </div>
                        </form>

                        {/* Investment Amount Input - Only show if token details are loaded */}
                        {customTokenDetails && (
                            <div style={{ marginTop: '15px' }}>
                                <h4>Investment Amount</h4>
                                <form onSubmit={handleInvestmentSubmit}>
                                    <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                                        <input
                                            type="number"
                                            value={investmentAmount}
                                            onChange={(e) => setInvestmentAmount(e.target.value)}
                                            placeholder={`Enter amount in ${customTokenDetails.symbol}`}
                                            step="any"
                                            min="0"
                                            style={{ 
                                                flex: 1, 
                                                padding: '8px', 
                                                borderRadius: '4px', 
                                                border: '1px solid #ccc' 
                                            }}
                                        />
                                        <button 
                                            type="submit" 
                                            disabled={!investmentAmount.trim() || !ready || loadingQuotes}
                                            style={{ 
                                                padding: '8px 16px', 
                                                borderRadius: '4px', 
                                                border: 'none', 
                                                backgroundColor: '#28a745', 
                                                color: 'white', 
                                                cursor: 'pointer' 
                                            }}
                                        >
                                            {loadingQuotes ? 'Calculating...' : 'Calculate Quotes'}
                                        </button>
                                    </div>
                                </form>
                            </div>
                        )}
                    </div>
                    
                    {(tickValues || token0Price !== null || token1Price !== null || customTokenDetails || customTokenBalance !== null || investmentQuotes) && (
                        <div style={{ border: '1px solid #ccc', margin: '10px 0', padding: '10px' }}>
                            <h3>Output Values</h3>
                            
                            {tickValues && (
                                <div>
                                    <h4>Tick Values:</h4>
                                    <pre style={{ backgroundColor: '#f5f5f5', padding: '10px', borderRadius: '4px', overflow: 'auto' }}>
                                        {JSON.stringify(tickValues, null, 2)}
                                    </pre>
                                </div>
                            )}
                            
                            {token0Price !== null && (
                                <div>
                                    <h4>Price (USD):</h4>
                                    <p><strong>{poolData.token0.symbol}: {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(parseFloat(token0Price))}</strong></p>
                                </div>
                            )}
                            
                            {token1Price !== null && (
                                <div>
                                    <h4>Price (USD):</h4>
                                    <p><strong>{poolData.token1.symbol}: {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(parseFloat(token1Price))}</strong></p>
                                </div>
                            )}

                            {/* Custom Token Information Display */}
                            {customTokenDetails && (
                                <div>
                                    <h4>Custom Token Details:</h4>
                                    <div style={{ backgroundColor: '#f5f5f5', padding: '10px', borderRadius: '4px' }}>
                                        <p><strong>Symbol:</strong> {customTokenDetails.symbol}</p>
                                        <p><strong>Address:</strong> {customTokenDetails.address}</p>
                                        <p><strong>Decimals:</strong> {customTokenDetails.decimals}</p>
                                    </div>
                                </div>
                            )}

                            {customTokenBalance !== null && (
                                <div>
                                    <h4>Token Balance:</h4>
                                    <p><strong>
                                        {parseFloat(customTokenBalance).toLocaleString()} {customTokenDetails?.symbol || 'tokens'}
                                        {customTokenUSDPrice !== null && (
                                            <span> (U$ {new Intl.NumberFormat('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(parseFloat(customTokenBalance) * parseFloat(customTokenUSDPrice))})</span>
                                        )}
                                    </strong></p>
                                </div>
                            )}

                            {/* Investment Quotes Display */}
                            {investmentQuotes && (
                                <div>
                                    <h4>Investment Quotes:</h4>
                                    <div style={{ backgroundColor: '#f5f5f5', padding: '10px', borderRadius: '4px' }}>
                                        {investmentQuotes.otherTokenQuote && (
                                            <p><strong>Quote for {investmentAmount} {customTokenDetails?.symbol} → {parseFloat(investmentQuotes.otherTokenQuote).toFixed(Number(poolData?.token1.decimals) || 18)} {poolData?.token1.symbol}</strong></p>
                                        )}
                                        {investmentQuotes.token0Quote && (
                                            <p><strong>Quote for {investmentAmount} {customTokenDetails?.symbol} → {parseFloat(investmentQuotes.token0Quote).toFixed(Number(poolData?.token0.decimals) || 18)} {poolData?.token0.symbol}</strong></p>
                                        )}
                                        {investmentQuotes.token1Quote && (
                                            <p><strong>Quote for {investmentAmount} {customTokenDetails?.symbol} → {parseFloat(investmentQuotes.token1Quote).toFixed(Number(poolData?.token1.decimals) || 18)} {poolData?.token1.symbol}</strong></p>
                                        )}
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            )}
        </div>
    )
}

export default NewPositionV2;
