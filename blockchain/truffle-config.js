var HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = 'YOUR_WALLET_PRIVATE_KEY';

module.exports = {
	plugins: ['truffle-security'],
	contracts_directory: './contracts',
	contracts_build_directory: './build',
	migrations_directory: './migrations',
	networks: {
		rinkeby: {
			provider: () =>
				new HDWalletProvider({
					privateKeys: [mnemonic],
					providerOrUrl: 'https://rinkeby.infura.io/v3/YOUR_INFURA_PROJECT_ID',
					numberOfAddresses: 1,
				}),
			network_id: 4,
			// gas: 10000000, // Max is 10000000
			gas: 4700000,
			confirmations: 2,
			timeoutBlocks: 200,
			skipDryRun: true,
			networkCheckTimeout: 1000000,
		},
		development: {
			host: '127.0.0.1',
			port: 7545,
			network_id: '*', // Match any network id
			// gas: 10000000, // Use `gas` & `gasPrice` only if creating type 0 transactions
			gas: 4700000,
			gasPrice: 20000000000, // (20 Gwei) All gas values specified in wei
		},
		compilers: {
			solc: {
				version: '^0.8.12', // native, pragma, ^0.8.12
				settings: {
					optimizer: {
						enabled: true,
						runs: 200,
					},
					evmVersion: 'istanbul', // homestead, tangerineWhistle, spuriousDragon, byzantium, constantinople, petersburg, istanbul or berlin
				},
			},
		},
	},
	compilers: {
		solc: {
			version: '^0.8.12', // native, pragma, ^0.8.12
			settings: {
				optimizer: {
					enabled: true,
					runs: 200,
				},
				evmVersion: 'istanbul', // homestead, tangerineWhistle, spuriousDragon, byzantium, constantinople, petersburg, istanbul or berlin
			},
		},
	},
	// environments: {
	//   development: {
	//     ipfs: {
	//       address: "http://localhost:5001",
	//     },
	//   },
	//   live: {
	//     ipfs: {
	//       address: "https://ipfs.infura.io:5001",
	//     },
	//   },
	// },
	// db: {
	//   enabled: false,
	//   host: "127.0.0.1",
	//   adapter: {
	//     name: "sqlite",
	//     settings: {
	//       directory: ".db",
	//     },
	//   },
	// },
};
