import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { PrivyProvider } from '@privy-io/react-auth';
import { baseSepolia, sepolia } from 'viem/chains';
import { Toaster } from 'react-hot-toast';
import { Buffer } from 'buffer'
import process from 'process'

// Make Buffer available globally
window.Buffer = Buffer
window.process = process

const privyAppId = import.meta.env.VITE_PRIVY_APP_ID

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <Toaster position="top-center" />
    <PrivyProvider
      appId={privyAppId}
      config={{
        loginMethods: ["wallet", "email", "google"],
        appearance: {
          theme: "light",
          accentColor: "#069478",
        },
        defaultChain: sepolia,
        supportedChains: [sepolia, baseSepolia],
        embeddedWallets: {
          createOnLogin: "users-without-wallets",
        },
      }}
    >
      <App />
    </PrivyProvider>
  </StrictMode>,
)
