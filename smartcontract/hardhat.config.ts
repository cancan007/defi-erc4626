import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const projectId = process.env.PROJECT_ID;
//const moralisId = process.env.AVALANCHE_TESTNET_ID;
//const avalancheFujiNodeC = process.env.AVALANCHE_FUJI_NODE_C;
const privateKey: any = process.env.PRIVATE_KEY;
const etherScanAPIKey = process.env.ETHERSCAN_API_KEY;

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: { enabled: true, runs: 200 },
    },
  },
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
    },
    kovan: {
      chainId: 42,
      url: `https://kovan.infura.io/v3/${projectId}`,
      accounts: [privateKey],
    },
    /*avalancheTestnet: {
      chainId: 43113,
      //url: `https://speedy-nodes-nyc.moralis.io/${moralisId}/avalanche/testnet`,
      url: `${avalancheFujiNodeC}`,
      accounts: [privateKey],
    },*/
    goerli: {
      chainId: 5,
      url: `https://goerli.infura.io/v3/${projectId}`,
      accounts: [privateKey],
    },
    sepolia: {
      chainId: 11155111,
      url: `https://sepolia.infura.io/v3/${projectId}`,
      accounts: [privateKey],
    },
    optimism: {
      chainId: 10,
      url: `https://optimism-mainnet.infura.io/v3/${projectId}`,
      accounts: [privateKey],
      //gasPrice: 35000000000
    },
    arbitrum: {
      chainId: 42161,
      url: `https://arbitrum-mainnet.infura.io/v3/${projectId}`,
      accounts: [privateKey],
    },
  },
  //to publish contract on etherscan to enable users can read or write the contract on etherscan
  etherscan: {
    apiKey: etherScanAPIKey,
  },
  // allowUnlimitedContractSize: true,
};

export default config;
