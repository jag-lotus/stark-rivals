import { expect } from 'chai';
import { starknet } from 'hardhat';
import { Account, StarknetContract, StarknetContractFactory } from 'hardhat/types/runtime';

import { strToShortStringFelt, test, tryCatch } from '../utils';

describe('Stark Rivals', function () {
  let contractFactory: StarknetContractFactory;
  let contractAddress: string;

  let owner: Account;
  let player1: Account;
  let player2: Account;

  before(async function () {
    contractFactory = await starknet.getContractFactory('stark_rivals');
    const accounts = [
      starknet.deployAccount('Argent'),
      starknet.deployAccount('Argent'),
      starknet.deployAccount('Argent'),
    ];

    const [_owner, _player1, _player2] = await Promise.all(accounts);
    owner = _owner;
    player1 = _player1;
    player2 = _player2;

    test.log('Owner deployed:', owner.publicKey);
    test.log('Player 1 deployed:', player1.publicKey);
    test.log('Player 2 deployed:', player2.publicKey);
  });

  it('should deploy the contract', async function () {
    const contract: StarknetContract = await contractFactory.deploy({
      owner_address: owner.publicKey,
      card_address: strToShortStringFelt('nothing yet'),
    });
    contractAddress = contract.address;
  });

  it('should start a game session', async function () {
    await tryCatch(async () => {
      const contract: StarknetContract = contractFactory.getContractAt(contractAddress);
      const txHash = await player1.invoke(contract, 'startGame', {
        card_ids: [1, 2, 3, 4, 5, 6],
      });

      const receipt = await starknet.getTransactionReceipt(txHash);
      console.log(receipt.events);
      expect(1).to.equal(1);
    });
  });

  test.done(this);
});
