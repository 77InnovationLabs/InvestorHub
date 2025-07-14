// components/TokenSelectionModal.tsx
import React, { useState } from 'react';
import { CircleDollarSign } from 'lucide-react';

// Interface para os tokens
interface MockToken {
    address: string;
    symbol: string;
    name: string;
    decimals: number;
}

interface TokenSelectionModalProps {
    isOpen: boolean;
    onClose: () => void;
    tokens: MockToken[];
    onSelectToken: (token: MockToken) => void;
}

const TokenSelectionModal: React.FC<TokenSelectionModalProps> = ({
    isOpen,
    onClose,
    tokens,
    onSelectToken,
}) => {
    const [searchTerm, setSearchTerm] = useState(""); // Estado para o termo de busca

    if (!isOpen) return null;

    // Filtra os tokens com base no termo de busca (case-insensitive)
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
                {/* Campo de busca */}
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
                <div className="space-y-2 max-h-[400px] overflow-y-auto">
                    {filteredTokens.length > 0 ? (
                        filteredTokens.map((token) => (
                            <div
                                key={token.address}
                                onClick={() => onSelectToken(token)}
                                className="flex items-center p-3 rounded-md hover:bg-gray-100 cursor-pointer transition-colors"
                            >
                                <div className="w-8 h-8 bg-gray-200 rounded-full flex items-center justify-center mr-3">
                                    <CircleDollarSign />
                                </div>
                                <div>
                                    <p className="text-sm font-medium text-gray-900">{token.symbol}</p>
                                    <p className="text-xs text-gray-500">{token.name}</p>
                                </div>
                            </div>
                        ))
                    ) : (
                        <p className="text-sm text-gray-500 text-center">No tokens found</p>
                    )}
                </div>
            </div>
        </div>
    );
};

export default TokenSelectionModal;