import '@shardlabs/starknet-hardhat-plugin';

import { HardhatUserConfig } from 'hardhat/config';

const config: HardhatUserConfig = {
  starknet: {
    venv: 'active',
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
  /*
  mocha: {
    starknetNetwork: 'starknet_devnet',
    // starknetNetwork: 'starkathon',
    // starknetNetwork: 'alpha',
  },
  */
};

export default config;
