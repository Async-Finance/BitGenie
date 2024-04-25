import * as dotenv from "dotenv";

import "@nomicfoundation/hardhat-toolbox";
import { HardhatUserConfig } from "hardhat/config";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    MerlinTestnet: {
      url: "https://testnet-rpc.merlinchain.io",
      accounts: [process.env.TEST_SECRET_KEY || ""],
      // gas: 30000000,
      // gasPrice: 50000000,
    },
    MerlinMainnet: {
      url: "https://rpc.merlinchain.io",
      accounts: [process.env.SECRET_KEY || ""],
      gas: 30000000,
      gasPrice: 50000000,
    },
  },
  sourcify: {
    enabled: false,
  },
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  mocha: {
    timeout: 40000,
  },
  // npx hardhat verify --network scrollTestnet 0x95ad51f4406bf2AF31e3A2e2d75262EE19432261 123
  etherscan: {
    apiKey: {
      MerlinTestnet: "abc",
      MerlinMainnet: "abc",
    },
    customChains: [
      {
        network: "MerlinTestnet",
        chainId: 686868,
        urls: {
          apiURL: "https://testnet-scan.merlinchain.io/api",
          browserURL: "https://testnet-scan.merlinchain.io",
        },
      },
      {
        network: "MerlinMainnet",
        chainId: 4200,
        urls: {
          apiURL: "https://scan.merlinchain.io/api",
          browserURL: "https://scan.merlinchain.io",
        },
      },
    ],
  },
};

export default config;
