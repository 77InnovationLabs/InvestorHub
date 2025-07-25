import React, { useCallback, useEffect, useState } from 'react';
import { CircleDollarSign } from 'lucide-react';
import { Token } from '../../interfaces/token';
import { getTokenBalance } from '../../utils/erc20/getTokenInformation';
import { ConnectedWallet } from '@privy-io/react-auth';

interface TokenSelectionModalProps {
    isOpen: boolean;
    onClose: () => void;
    onSelectToken: (token: Token) => void;
    privyWallets: ConnectedWallet[];
}

const TokenSelectionModal: React.FC<TokenSelectionModalProps> = ({
    isOpen,
    onClose,
    onSelectToken,
    privyWallets,
}) => {
    const [searchTerm, setSearchTerm] = useState("");
    const [tokens, setTokens] = useState<Token[]>([]);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState<string | null>(null);
    const [tokenBalances, setTokenBalances] = useState<{ [address: string]: string }>({});

    // fetch tokens from api
    const fetchTokenList = useCallback(async () => {
        if (privyWallets.length === 0) {
            setError('No wallet connected');
            setTokens([]);
            setLoading(false);
            return;
        }

        setLoading(true);
        setError(null);

        try {
            const chainId = privyWallets[0].chainId.replace('eip155:', '');
            const apiUrl = new URL(`${import.meta.env.VITE_API_URL}/tokens`);
            apiUrl.searchParams.append('chainId', chainId);
            apiUrl.searchParams.append('whitelist', 'true');

            const response = await fetch(apiUrl.toString(), {
                method: 'GET',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                },
            });

            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }

            const data = await response.json();

            if (!Array.isArray(data)) {
                throw new Error('Unexpected response format: Expected an array of tokens');
            }

            const balances: { [address: string]: string } = {};
            const validTokens: Token[] = [];

            for (const token of data) {
                try {
                    const balance = await getTokenBalance(privyWallets[0], token.address);
                    if (parseFloat(balance) > 0) {
                        validTokens.push(token);
                        balances[token.address] = balance;
                    }
                } catch (balanceError) {
                    console.warn(`Failed to fetch balance for ${token.symbol}:`, balanceError);
                }
            }

            setTokens(validTokens);
            setTokenBalances(balances);
        } catch (err) {
            setError(err instanceof Error ? err.message : 'Failed to load token list');
            console.error('Error fetching token list:', err);
            setTokens([]);
            setTokenBalances({});
        } finally {
            setLoading(false);
        }
    }, [privyWallets]);

    useEffect(() => {
        if (isOpen) {
            fetchTokenList();
        }
    }, [isOpen, fetchTokenList]);

    if (!isOpen) return null;

    const filteredTokens = tokens.filter(
        (token) =>
            token.symbol.toLowerCase().includes(searchTerm.toLowerCase()) ||
            token.name.toLowerCase().includes(searchTerm.toLowerCase())
    );

    return (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
            <div className="bg-white rounded-xl p-6 w-full max-w-md mx-4">
                <div className="flex justify-between items-center mb-4">
                    <h2 className="text-lg font-semibold text-gray-900">Select a Token</h2>
                    <button
                        onClick={onClose}
                        className="text-gray-500 hover:text-gray-700 hover:bg-zinc-100 rounded-full p-2 cursor-pointer"
                    >
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path
                                strokeLinecap="round"
                                strokeLinejoin="round"
                                strokeWidth="2"
                                d="M6 18L18 6M6 6l12 12"
                            />
                        </svg>
                    </button>
                </div>
                {/* Search */}
                <div className="relative mb-4">
                    <input
                        type="text"
                        value={searchTerm}
                        onChange={(e) => setSearchTerm(e.target.value)}
                        placeholder="Search tokens..."
                        className="w-full pl-10 pr-4 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-sky-500 focus:border-sky-500"
                    />
                    <svg
                        className="w-5 h-5 absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400"
                        fill="none"
                        stroke="currentColor"
                        viewBox="0 0 24 24"
                    >
                        <path
                            strokeLinecap="round"
                            strokeLinejoin="round"
                            strokeWidth="2"
                            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
                        />
                    </svg>
                </div>
                {/* Loading */}
                {loading && (
                    <div className="text-center py-5">
                        <div className="animate-spin rounded-full h-5 w-5 border-t-2 border-b-2 border-sky-600 mx-auto mb-2"></div>
                        <p className="text-xs text-zinc-500">Loading tokens...</p>
                    </div>
                )}
                {/* Token List */}
                {!loading && !error && (
                    <div className="space-y-2 max-h-[400px] overflow-y-auto">
                        {filteredTokens.length > 0 ? (
                            filteredTokens.map((token) => (
                                <div
                                    key={token.address}
                                    onClick={() => onSelectToken(token)}
                                    className="flex items-center justify-between p-3 rounded-md hover:bg-gray-100 cursor-pointer transition-colors"
                                >
                                    <div className="flex items-center">
                                        <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center mr-3">
                                            <CircleDollarSign />
                                        </div>
                                        <div>
                                            <p className="text-sm font-medium text-gray-900">{token.symbol}</p>
                                            <p className="text-xs text-gray-500">{token.name}</p>
                                        </div>
                                    </div>
                                    <div className="text-sm text-gray-600">
                                        {parseFloat(tokenBalances[token.address]).toLocaleString(undefined, {
                                            minimumFractionDigits: 2,
                                            maximumFractionDigits: 6,
                                        })}{' '}
                                        {token.symbol}
                                    </div>
                                </div>
                            ))
                        ) : (
                            <p className="text-sm text-gray-500 text-center">No tokens with balance found</p>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
};

export default TokenSelectionModal;