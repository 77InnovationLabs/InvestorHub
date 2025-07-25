import React, { useState, useEffect } from 'react';
import { ConnectedWallet, useWallets } from '@privy-io/react-auth';
import { Link, useParams } from 'react-router-dom';
import { calculateTickValues } from '../utils/uniswap/getTickValues';
import { PoolData } from '../interfaces/pooldata';
import { getTokenPriceQuote, getBestUSDPriceQuote } from '../utils/uniswap/getQuote';
import { getTokenDetails, getTokenBalance } from '../utils/erc20/getTokenInformation';
import { PartialToken, Token } from '../interfaces/token';
import { startSwapAndWait } from '../utils/aggregator/investStartSwap';
import { FullSwapParams, StartSwapParams } from '../interfaces/startswapparams';
import { checkAndExecuteApprovalAndWait } from '../utils/erc20/executeapprovals';
import { fromReadableAmount } from '../utils/convertions';
import { ArrowLeft, ChevronDown, CircleDollarSign } from 'lucide-react';
import TokenSelectionModal from '../components/ui/token-selection-modal';
import { startFullSwapAndWait } from '../utils/aggregator/investFullSwap';
import { NETWORKS_CONFIGS } from '../utils/constants';

const NewPositionV3: React.FC = () => {
    const { id } = useParams<{ id: string }>();
    const [poolData, setPoolData] = useState<PoolData | null>(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [tickValues, setTickValues] = useState<any>(null);
    const [isTheSameNetwork, setIsTheSameNetwork] = useState(false);
    const [token0Price, setToken0Price] = useState<string | null>(null);
    const [token1Price, setToken1Price] = useState<string | null>(null);
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
    const [splitAmounts, setSplitAmounts] = useState<{
        token0Amount?: string;
        token1Amount?: string;
        token0USDValue?: string;
        token1USDValue?: string;
    } | null>(null);

    console.log(error); //TODO: remove this

    const [isModalOpen, setIsModalOpen] = useState(false);

    const isWalletConnected = ready && privyWallets.length > 0;

    const handleTokenSelect = (token: Token) => {
        setIsModalOpen(false);
        if (isWalletConnected) {
            fetchCustomTokenInfo(token.address);
        } else {
            setError('Por favor, conecte sua carteira para selecionar um token.');
        }
    };

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
    };

    const getUSDPrice = async (connectedWallet: ConnectedWallet, token0: PartialToken, isTheSameNetwork: boolean) => {
        if (isTheSameNetwork) {
            const quoteResponse = await getBestUSDPriceQuote(connectedWallet, token0, isTheSameNetwork);
            return quoteResponse;
        } else {
            // Call backend API
            const network = `eip155:${token0?.network?.chainId}`;
            const apiUrl = `${import.meta.env.VITE_API_URL}/quote/usd-price`;
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    network,
                    tokenAddress: token0.address,
                    tokenDecimals: token0.decimals,
                    tokenSymbol: token0.symbol,
                }),
            });
            if (!response.ok) {
                throw new Error(`Failed to fetch USD price from backend: ${response.statusText}`);
            }
            const data = await response.json();
            return data;
        }
    };

    const getTickValues = async (connectedWallet: ConnectedWallet, pool: PoolData, isTheSameNetwork: boolean) => {
        if (isTheSameNetwork) {
            const tickValuesData = await calculateTickValues(connectedWallet, pool?.address, isTheSameNetwork);
            return tickValuesData;
        } else {
            // Call backend API
            const network = `eip155:${pool?.token0?.network?.chainId}`;
            const apiUrl = `${import.meta.env.VITE_API_URL}/tick/tick-values`;
            const response = await fetch(apiUrl, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    network,
                    poolAddress: pool?.address,
                }),
            });
            if (!response.ok) {
                throw new Error(`Failed to fetch tick values from backend: ${response.statusText}`);
            }
            const data = await response.json();
            return data;
        }
    };

    const fetchCustomTokenInfo = async (address: string) => {
        if (!address.trim() || !ready || privyWallets.length === 0) {
            return;
        }

        setLoadingTokenInfo(true);
        setError(null);

        try {
            const [tokenDetails, tokenBalance] = await Promise.all([
                getTokenDetails(privyWallets[0], address.trim()),
                getTokenBalance(privyWallets[0], address.trim()),
            ]);

            setCustomTokenDetails(tokenDetails);
            setCustomTokenBalance(tokenBalance);

            try {
                const usdPrice = await getUSDPrice(privyWallets[0], tokenDetails, true); // This will be always true because the user has to select the token from the same network
                setCustomTokenUSDPrice(usdPrice.quote);
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

    const investInPool = async () => {
        if (
            !tickValues ||
            !investmentAmount.trim() ||
            !customTokenDetails ||
            !customTokenDetails.decimals ||
            !poolData ||
            !poolData.token1.decimals ||
            !poolData.token0.decimals ||
            !ready ||
            privyWallets.length === 0
        ) {
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
                    decimals: otherToken.decimals,
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

                // Atribuir amountOut a quotes.otherTokenQuote para exibição
                quotes.otherTokenQuote = amountOut;

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
                        amount1Desired: (
                            BigInt(fromReadableAmount(Number(amountOut), Number(otherToken.decimals))) *
                            BigInt(85) /
                            BigInt(100)
                        ).toString(), // Slippage 15%
                        amount0Min: "0",
                        amount1Min: "0",
                        recipient: privyWallets[0].address,
                        deadline: (Math.floor(Date.now() / 1000) + 900).toString(),
                    },
                };

                await checkAndExecuteApprovalAndWait(
                    customTokenDetails.address,
                    fromReadableAmount(Number(investmentAmount), Number(customTokenDetails.decimals)).toString(),
                    privyWallets[0]
                );

                const tx = await startSwapAndWait(privyWallets[0], startSwapParams);
                console.log("Swap transaction:", tx);
            } else {
                // If typed token is not one of the pool tokens
                const token0Formatted: Token = {
                    ...poolData.token0,
                    decimals: poolData.token0.decimals,
                };
                const token1Formatted: Token = {
                    ...poolData.token1,
                    decimals: poolData.token1.decimals,
                };

                // Get quotes for both tokens
                const quoteToken0 = await getTokenPriceQuote(
                    privyWallets[0],
                    customTokenDetails,
                    token0Formatted,
                    Number(poolData.feeTier),
                    halfInvestment
                );

                const quoteToken1 = await getTokenPriceQuote(
                    privyWallets[0],
                    customTokenDetails,
                    token1Formatted,
                    Number(poolData.feeTier),
                    halfInvestment
                );

                quotes.token0Quote = quoteToken0.amountOut;
                quotes.token1Quote = quoteToken1.amountOut;
                console.log(`Quote for ${customTokenDetails.symbol} to ${poolData.token0.symbol}:`, quoteToken0);
                console.log(`Quote for ${customTokenDetails.symbol} to ${poolData.token1.symbol}:`, quoteToken1);

                await checkAndExecuteApprovalAndWait(
                    customTokenDetails.address,
                    fromReadableAmount(Number(investmentAmount), Number(customTokenDetails.decimals)).toString(),
                    privyWallets[0]
                );

                const fullSwapParams: FullSwapParams = {
                    inputToken: customTokenDetails.address,
                    totalAmountIn: fromReadableAmount(Number(investmentAmount), Number(customTokenDetails.decimals)).toString(),
                    payload: [{ 
                        path: quoteToken0.path,
                        amountInForInputToken: fromReadableAmount(Number(halfInvestment), Number(customTokenDetails.decimals)).toString(),
                        deadline: "0",
                    }, {
                        path: quoteToken1.path,
                        amountInForInputToken: fromReadableAmount(Number(halfInvestment), Number(customTokenDetails.decimals)).toString(),
                        deadline: "0",
                    }],
                    stakePayload: {
                        token0: poolData.token0.address,
                        token1: poolData.token1.address,
                        fee: Number(poolData.feeTier),
                        tickLower: tickValues.minTick,
                        tickUpper: tickValues.maxTick,
                        amount0Desired: (
                            BigInt(fromReadableAmount(Number(quoteToken0.amountOut), Number(poolData.token0.decimals))) *
                            BigInt(85) /
                            BigInt(100)
                        ).toString(),
                        amount1Desired: (
                            BigInt(fromReadableAmount(Number(quoteToken1.amountOut), Number(poolData.token1.decimals))) *
                            BigInt(85) /
                            BigInt(100)
                        ).toString(), // Slippage 15%
                        amount0Min: "0",
                        amount1Min: "0",
                        recipient: privyWallets[0].address,
                        deadline: (Math.floor(Date.now() / 1000) + 900).toString(),
                    },
                };

                const tx = await startFullSwapAndWait(privyWallets[0], fullSwapParams);
                console.log("Swap transaction:", tx);
            }

            setInvestmentQuotes(quotes);
        } catch (err) {
            setError(err instanceof Error ? err.message : "Failed to calculate investment quotes");
            console.error("Error calculating investment quotes:", err);
            setInvestmentQuotes(null);
        } finally {
            setLoadingQuotes(false);
        }
    };

    const handleInvestmentSubmit = (e: React.FormEvent) => {
        e.preventDefault();
        investInPool();
    };

    const calculateSplitAmounts = async (amount: string) => {
        if (!amount.trim() || !customTokenDetails || !poolData || !ready || privyWallets.length === 0) {
            setSplitAmounts(null);
            return;
        }

        try {
            const investmentValue = parseFloat(amount);
            if (isNaN(investmentValue) || investmentValue <= 0) {
                setSplitAmounts(null);
                return;
            }

            // 1. Calcular o valor total em USD do investimento
            const totalUSDValue = investmentValue * parseFloat(customTokenUSDPrice || '0');
            const halfUSDValue = totalUSDValue / 2;

            // 2. Verificar se o token de entrada é um dos tokens da pool
            const isToken0 = customTokenDetails.address.toLowerCase() === poolData.token0.address.toLowerCase();
            const isToken1 = customTokenDetails.address.toLowerCase() === poolData.token1.address.toLowerCase();

            if (isToken0 || isToken1) {
                // Caso 1: O token de entrada é um dos tokens da pool
                // const stayToken = isToken0 ? poolData.token0 : poolData.token1;
                // const swapToken = isToken0 ? poolData.token1 : poolData.token0;
                const stayTokenPrice = isToken0 ? token0Price : token1Price;
                const swapTokenPrice = isToken0 ? token1Price : token0Price;

                // 3. Calcular quanto do token de entrada manter (em quantidade)
                const stayAmount = investmentValue / 2;
                const stayUSDValue = stayAmount * parseFloat(stayTokenPrice || '0');

                // 4. Calcular quanto do outro token precisamos para igualar o valor USD
                const swapAmountUSD = halfUSDValue;
                const swapAmount = swapAmountUSD / parseFloat(swapTokenPrice || '1');

                setSplitAmounts({
                    token0Amount: isToken0 ? stayAmount.toString() : swapAmount.toString(),
                    token1Amount: isToken1 ? stayAmount.toString() : swapAmount.toString(),
                    token0USDValue: isToken0 ? stayUSDValue.toString() : swapAmountUSD.toString(),
                    token1USDValue: isToken1 ? stayUSDValue.toString() : swapAmountUSD.toString()
                });
            } else {
                // Caso 2: O token de entrada não é um dos tokens da pool
                // 5. Dividir igualmente em USD e converter para cada token
                const token0Amount = halfUSDValue / parseFloat(token0Price || '1');
                const token1Amount = halfUSDValue / parseFloat(token1Price || '1');

                setSplitAmounts({
                    token0Amount: token0Amount.toString(),
                    token1Amount: token1Amount.toString(),
                    token0USDValue: halfUSDValue.toString(),
                    token1USDValue: halfUSDValue.toString()
                });
            }
        } catch (err) {
            console.error("Error calculating split amounts:", err);
            setSplitAmounts(null);
        }
    };

    const checkTheSameNetwork = async (name: string) => {
        if (privyWallets.length > 0) {
            setIsTheSameNetwork(name === NETWORKS_CONFIGS[privyWallets[0].chainId].name);
            return name === NETWORKS_CONFIGS[privyWallets[0].chainId].name;
        } 
        
        setIsTheSameNetwork(false);
        return false;

    }

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
                if (ready) {
                    const isTheSameNetworkParam = await checkTheSameNetwork(data.token0.network.name); // TODO: Better way to check if the network is the same
                    const tickValuesData = await getTickValues(privyWallets[0], data, isTheSameNetworkParam);
                    setTickValues(tickValuesData);
                    console.log('Tick values:', tickValuesData);
                    const token0PriceData = await getUSDPrice(privyWallets[0], data.token0, isTheSameNetworkParam);
                    const token1PriceData = await getUSDPrice(privyWallets[0], data.token1, isTheSameNetworkParam);
                    console.log('[TOKEN0]Token0 price data:', token0PriceData);
                    console.log('[TOKEN1] Token1 price data:', token1PriceData);
                    setToken0Price(token0PriceData.quote);
                    setToken1Price(token1PriceData.quote);
                    console.log('Token0 price:', token0PriceData);
                    console.log('Token1 price:', token1PriceData);
                    console.log('Is the same network:', isTheSameNetwork);
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
        <div className="max-w-[1600px] mx-auto py-8 px-2 sm:px-6 lg:px-12 bg-gray-50">
            {loading && <div className="text-center py-4">
                <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-sky-600 mx-auto mb-2"></div>
                <p className='text-xs text-zinc-500'>Loading...</p>
            </div>}

            {/* {error && (
                <div style={{ color: 'red', margin: '10px 0' }}>
                    Error: {error}
                </div>
            )} */}

            {!isWalletConnected && (
                <div className='flex items-center justify-center'>
                    <div className="bg-sky-100 border border-sky-400 text-sky-700 px-4 py-3 rounded-md mb-4 w-fit">
                        Connect your wallet to start investing!
                    </div>
                </div>
            )}

            <Link to="/dashboard/pools" className="flex items-center text-sky-600 hover:underline mb-6">
                <ArrowLeft size={16} className="mr-2" />
                Back to Pools
            </Link>

            {poolData && (
                <div className="bg-white rounded-xl shadow-sm border-t-2 border-sky-50 sm:p-6">
                    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 lg:w-[900px]">
                        <div className="space-y-2 pt-2 w-96 min-h-full">
                            <h1 className="text-xl font-bold text-gray-900 ml-4">Start Investing</h1>

                            <div className="space-y-2">
                                <div className='px-4'>
                                    <p className="text-sm text-gray-500">Token Pair</p>
                                    <p className="text-xl font-bold text-gray-800">
                                        {poolData.token0.symbol}/{poolData.token1.symbol}
                                    </p>
                                </div>

                                <div className='px-4'>
                                    <p className="text-sm text-gray-500">Fee Tier</p>
                                    <p className="text-sm font-medium text-gray-900">
                                        {(parseFloat(poolData.feeTier) / 10000).toFixed(2)}%
                                    </p>
                                </div>

                                {poolData.poolDayData.length > 0 && (
                                    <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                                        <h4 className="font-semibold text-gray-900">Statistics</h4>
                                        <div className="grid grid-cols-2 gap-4 text-sm">
                                            <div>
                                                <span className="text-gray-500">Total TVL</span>
                                                <p className="font-semibold">${poolData.poolDayData.slice(0, 3).reduce((sum, dayData) => sum + parseFloat(dayData.tvlUSD), 0).toLocaleString()}</p>
                                            </div>
                                            <div>
                                                <span className="text-gray-500">Total Volume</span>
                                                <p className="font-semibold">${poolData.poolDayData.slice(0, 3).reduce((sum, dayData) => sum + parseFloat(dayData.volumeUSD), 0).toLocaleString()}</p>
                                            </div>
                                            <div>
                                                <span className="text-gray-500">Total Fees</span>
                                                <p className="font-semibold">${poolData.poolDayData.slice(0, 3).reduce((sum, dayData) => sum + parseFloat(dayData.feesUSD), 0).toLocaleString()}</p>
                                            </div>
                                            <div>
                                                <span className="text-gray-500">Avg APR</span>
                                                <p className="font-semibold text-green-600">{(poolData.poolDayData.slice(0, 3).reduce((sum, dayData) => sum + parseFloat(dayData.apr24h), 0) / poolData.poolDayData.slice(0, 3).length).toFixed(2)}%</p>
                                            </div>
                                        </div>
                                    </div>
                                )}

                                <div className="bg-gray-50 rounded-lg p-4 space-y-2">
                                    <h4 className="font-semibold text-gray-900">Current Prices</h4>
                                    <div className="grid grid-cols-2 gap-4 text-sm">
                                        {token0Price !== null && (
                                            <div>
                                                <span className="text-gray-500">{poolData.token0.symbol} Price</span>
                                                <p className="font-semibold">
                                                    {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(parseFloat(token0Price))}
                                                </p>
                                            </div>
                                        )}
                                        {token1Price !== null && (
                                            <div>
                                                <span className="text-gray-500">{poolData.token1.symbol} Price</span>
                                                <p className="font-semibold">
                                                    {new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(parseFloat(token1Price))}
                                                </p>
                                            </div>
                                        )}
                                    </div>
                                </div>

                            </div>
                        </div>

                        <div className="space-y-2 pt-2 flex flex-col flex-1/2 min-h-full justify-between">
                            <div className="space-y-2 flex flex-col px-4 sm:px-0">
                                <div className="space-y-2 flex flex-col">
                                    <div className="flex flex-col sm:flex-row justify-between gap-2">
                                        <input
                                            type="number"
                                            value={investmentAmount}
                                            onChange={(e) => {
                                                setInvestmentAmount(e.target.value);
                                                calculateSplitAmounts(e.target.value);
                                            }}
                                            placeholder="0"
                                            step="any"
                                            min="0"
                                            disabled={!customTokenDetails}
                                            className="w-full sm:w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-sky-500 focus:border-sky-500 flex items-center justify-center"
                                        />
                                        <button
                                            type="button"
                                            onClick={() => {
                                                setInvestmentAmount('');
                                                setSplitAmounts(null);
                                                setIsModalOpen(true);
                                            }}
                                            className="w-full sm:w-fit flex flex-row justify-between items-center space-x-2 bg-sky-600 hover:bg-sky-700 text-white py-3 px-4 rounded-md font-medium transition-colors duration-200 disabled:opacity-50 cursor-pointer"
                                            disabled={!ready || loadingTokenInfo || privyWallets.length === 0}
                                            title={privyWallets.length === 0 ? 'Connect a wallet to select a token' : ''}
                                        >
                                            <div className="rounded-full bg-sky-600 w-5 h-5 flex items-center justify-center">
                                                <CircleDollarSign />
                                            </div>
                                            <span className="whitespace-nowrap">
                                                {customTokenDetails ? `${customTokenDetails.symbol}` : 'Select Token'}
                                            </span>
                                            <ChevronDown className="w-6 ml-2" />
                                        </button>
                                    </div>
                                    {loadingTokenInfo ? (
                                        <div className="flex flex-col justify-end items-end mt-2 mr-4">
                                            <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-sky-600 mb-4"></div>
                                        </div>
                                    ) : (
                                        (tickValues ||
                                            token0Price !== null ||
                                            token1Price !== null ||
                                            customTokenDetails ||
                                            customTokenBalance !== null ||
                                            investmentQuotes) && (
                                            <div className="rounded-lg pb-2 mr-4">
                                                <div className="flex justify-end">
                                                    {(customTokenDetails || customTokenBalance !== null) && (
                                                        <div className="rounded-lg w-full flex items-start justify-end">
                                                            {customTokenBalance !== null && (
                                                                <div className="flex flex-row items-start gap-2">
                                                                    <p className="font-semibold text-right text-sm">
                                                                        {parseFloat(customTokenBalance).toLocaleString()}{" "}
                                                                        {customTokenDetails?.symbol || "tokens"}
                                                                        {customTokenUSDPrice !== null && (
                                                                            <span className="block text-xs font-semibold text-gray-600">
                                                                                $
                                                                                {new Intl.NumberFormat("en-US", {
                                                                                    minimumFractionDigits: 2,
                                                                                    maximumFractionDigits: 2,
                                                                                }).format(
                                                                                    parseFloat(customTokenBalance) *
                                                                                    parseFloat(customTokenUSDPrice)
                                                                                )}
                                                                            </span>
                                                                        )}
                                                                    </p>
                                                                </div>
                                                            )}
                                                        </div>
                                                    )}
                                                </div>
                                            </div>
                                        )
                                    )}
                                </div>
                            </div>

                            <TokenSelectionModal
                                isOpen={isModalOpen}
                                onClose={() => setIsModalOpen(false)}
                                onSelectToken={handleTokenSelect}
                                privyWallets={privyWallets}
                            />

                            {splitAmounts && (
                                <form onSubmit={handleInvestmentSubmit}>
                                    <div className="rounded-lg shadow-sm">
                                        <div className="p-4 space-y-2">
                                            {/* Allocation Breakdown */}
                                            <div className='space-y-2'>
                                                <h4 className="text-sm font-medium text-end text-gray-500">Allocation Breakdown</h4>
                                                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                                                    {/* Token 0 Allocation */}
                                                    <div className="bg-gray-50 p-4 rounded-lg border border-gray-100">
                                                        <div className="flex justify-between items-start">
                                                            <div>
                                                                <p className="text-sm font-medium text-gray-500">{poolData?.token0.symbol}</p>
                                                                <p className="text-2xl font-bold text-gray-800 mt-1">
                                                                    {parseFloat(splitAmounts?.token0Amount || '0').toLocaleString(undefined, {
                                                                        minimumFractionDigits: 2,
                                                                        maximumFractionDigits: 6,
                                                                    })}
                                                                </p>
                                                            </div>
                                                            <div className="bg-sky-100 text-sky-800 px-2 py-1 rounded-md text-xs font-medium">
                                                                ${parseFloat(splitAmounts?.token0USDValue || '0').toFixed(2)}
                                                            </div>
                                                        </div>
                                                        <div className="mt-3">
                                                            <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
                                                                <div className="h-full bg-sky-500" style={{ width: '50%' }}></div>
                                                            </div>
                                                        </div>
                                                    </div>

                                                    {/* Token 1 Allocation */}
                                                    <div className="bg-gray-50 p-4 rounded-lg border border-gray-100">
                                                        <div className="flex justify-between items-start">
                                                            <div>
                                                                <p className="text-sm font-medium text-gray-500">{poolData?.token1.symbol}</p>
                                                                <p className="text-2xl font-bold text-gray-800 mt-1">
                                                                    {parseFloat(splitAmounts?.token1Amount || '0').toLocaleString(undefined, {
                                                                        minimumFractionDigits: 2,
                                                                        maximumFractionDigits: 6,
                                                                    })}
                                                                </p>
                                                            </div>
                                                            <div className="bg-sky-100 text-sky-800 px-2 py-1 rounded-md text-xs font-medium">
                                                                ${parseFloat(splitAmounts?.token1USDValue || '0').toFixed(2)}
                                                            </div>
                                                        </div>
                                                        <div className="mt-3">
                                                            <div className="h-2 bg-gray-200 rounded-full overflow-hidden">
                                                                <div className="h-full bg-sky-500" style={{ width: '50%' }}></div>
                                                            </div>
                                                        </div>
                                                    </div>
                                                </div>
                                            </div>

                                            <div className="flex justify-end items-center my-4">
                                                <div className="text-right">
                                                    <p className="text-sm font-medium text-gray-500">Total Investment</p>
                                                    <p className="text-md font-bold text-sky-600">
                                                        ${(parseFloat(investmentAmount || '0') * parseFloat(customTokenUSDPrice || '0')).toFixed(2)}
                                                    </p>
                                                </div>
                                            </div>

                                            <button
                                                type="submit"
                                                className="w-full bg-sky-600 hover:bg-sky-700 text-white py-3 px-4 rounded-md font-medium transition-colors duration-200 disabled:opacity-50 cursor-pointer"
                                                disabled={!investmentAmount.trim() || !ready || loadingQuotes}
                                            >
                                                {loadingQuotes ? 'Investing...' : 'Invest Now'}
                                            </button>
                                        </div>
                                    </div>
                                </form>
                            )}
                        </div>
                    </div>
                </div>
            )}
        </div>
    )
}

export default NewPositionV3;
