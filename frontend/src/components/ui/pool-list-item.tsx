import React from 'react';
import { ArrowRight } from 'lucide-react';
import Button from './button';
import { Link } from 'react-router-dom';
import { TokenInfo, PoolDayData } from '../../interfaces/pooldata';

interface PoolListItemProps {
    _id: string;
    feeTier: string;
    token0: TokenInfo;
    token1: TokenInfo;
    poolDayData: PoolDayData[];
}

const PoolListItem: React.FC<PoolListItemProps> = ({
    _id,
    feeTier,
    token0,
    token1,
    poolDayData,
}) => {
    const latestData = poolDayData && poolDayData.length > 0
        ? poolDayData.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime())[0]
        : { apr24h: '0', tvlUSD: '0', volumeUSD: '0' };
    const apr = latestData.apr24h ? `${parseFloat(latestData.apr24h).toFixed(2)}%` : 'N/A';
    const tvl = latestData.tvlUSD
        ? `$${Number(latestData.tvlUSD).toLocaleString('en-US', { maximumFractionDigits: 0 })}`
        : 'N/A';
    const volume = latestData.volumeUSD
        ? `$${Number(latestData.volumeUSD).toLocaleString('en-US', { maximumFractionDigits: 0 })}`
        : 'N/A';
    const networkName = token0.network?.name || 'Unknown';
    const feeTierPercentage = (Number(feeTier) / 10000).toFixed(2) + '%';

    return (
        <div className="bg-white rounded-xl shadow-sm border-t-2 border-sky-50 hover:shadow-md transition-all duration-300 p-4 mb-2">
            <div className="mb-1.5">
                <h3 className="text-base font-bold text-gray-900">
                    {token0.symbol}/{token1.symbol}
                </h3>
            </div>
            <div className="flex items-center gap-3 overflow-x-auto">
                <div className="min-w-[100px]">
                    <span className="text-[10px] font-medium text-gray-500 uppercase hidden sm:block">APR (24h)</span>
                    <p className="text-sm font-semibold text-emerald-600 truncate">{apr}</p>
                </div>
                <div className="min-w-[100px] border-l border-gray-200 pl-3">
                    <span className="text-[10px] font-medium text-gray-500 uppercase hidden sm:block">TVL</span>
                    <p className="text-sm font-semibold text-gray-800 truncate">{tvl}</p>
                </div>
                <div className="min-w-[100px] border-l border-gray-200 pl-3">
                    <span className="text-[10px] font-medium text-gray-500 uppercase hidden sm:block">FEE TIER</span>
                    <p className="text-sm font-semibold text-gray-800 truncate">{feeTierPercentage}</p>
                </div>
                <div className="min-w-[100px] border-l border-gray-200 pl-3">
                    <span className="text-[10px] font-medium text-gray-500 uppercase hidden sm:block">Volume (24h)</span>
                    <p className="text-sm font-semibold text-gray-800 truncate">{volume}</p>
                </div>
                <div className="min-w-[100px] border-l border-gray-200 pl-3">
                    <span className="text-[10px] font-medium text-gray-500 uppercase hidden sm:block">Network</span>
                    <p className="text-sm font-semibold text-gray-800 truncate">{networkName}</p>
                </div>
                <Link to={`/dashboard/new-position-v3/${_id}`} className="inline-flex ml-3">
                    <Button
                        size="sm"
                        className="text-sm font-semibold text-white bg-gradient-to-r from-sky-500 to-sky-600 hover:from-sky-700 hover:to-sky-800 px-3 py-1.5 rounded-md shadow-sm"
                        icon={<ArrowRight size={12} />}
                    >
                        Invest
                    </Button>
                </Link>
            </div>
        </div>
    );
};

export default PoolListItem;