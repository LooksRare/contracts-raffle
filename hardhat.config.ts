import type { HardhatUserConfig } from "hardhat/types";
import { task } from "hardhat/config";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "solidity-coverage";
import "dotenv/config";

task("accounts", "Prints the list of accounts", async (_args, hre) => {
  const accounts = await hre.ethers.getSigners();
  accounts.forEach(async (account) => console.info(account.address));
});

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    mainnet: {
      url: "https://rpc.ankr.com/eth",
      chainId: 1,
    },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      chainId: 5,
    },
    hardhat: {
      allowUnlimitedContractSize: false,
      hardfork: "berlin", // Berlin is used (temporarily) to avoid issues with coverage
      mining: {
        auto: true,
        interval: 50000,
      },
      gasPrice: "auto",
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY,
  },
  solidity: {
    compilers: [
      {
        version: "0.8.20",
        settings: { optimizer: { enabled: true, runs: 888888 } },
      },
    ],
  },
  paths: {
    sources: "./contracts/",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  abiExporter: {
    path: "./abis",
    runOnCompile: true,
    clear: true,
    flat: true,
    pretty: false,
    except: ["test*"],
  },
  gasReporter: {
    enabled: !!process.env.REPORT_GAS,
    excludeContracts: ["test*"],
  },
};

export default config;
