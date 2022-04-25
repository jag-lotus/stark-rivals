import '@shardlabs/starknet-hardhat-plugin';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
  starknet: {
    venv: 'active',
    network: 'starknet_devnet',
  },
  paths: {
    starknetSources: 'contracts',
  },
  networks: {
    starknet_devnet: {
      url: 'http://localhost:5000/',
    },
    starkathon: {
      url: 'hackathon-0.starknet.io',
    },
  },
  mocha: {
    timeout: '5m',
  },
};

export default config;
