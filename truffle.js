require('dotenv').config();  // Store environment-specific variable from '.env' to process.env
require('babel-register');
require('babel-polyfill');

const HDWalletProvider = require("truffle-hdwallet-provider");


module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  gasPrice: 100000000000,
  solc: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 9545, // 8545 for ganachi-cli, 9545 for truffle develop
      network_id: "*", // Match any network id
	  gas: 6721975,
	  gasPrice: 100000000000,
    },
	// testnets
    // properties
    // network_id: identifier for network based on ethereum blockchain. Find out more at https://github.com/ethereumbook/ethereumbook/issues/110
    // gas: gas limit
    // gasPrice: gas price in gwei
	ropsten: {
      provider: () =>
		new HDWalletProvider(process.env.MNEMONIC, "https://ropsten.infura.io/v3/" + process.env.INFURA_API_KEY),
      network_id: 3
    },
	// main ethereum network(mainnet)
    main: {
      provider: () => new HDWalletProvider(process.env.MNENOMIC, "https://mainnet.infura.io/v3/" + process.env.INFURA_API_KEY),
      network_id: 1,
      gas: 3000000,
      gasPrice: 21
    }
  }
};
