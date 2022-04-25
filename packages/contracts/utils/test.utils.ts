import { Event } from '@shardlabs/starknet-hardhat-plugin/dist/starknet-types';
import { expect } from 'chai';
import { hash } from 'starknet';

export const test = {
  log: (...str: string[]) => console.log('   ', ...str),
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  done: (module: any) => module.afterAll(() => process.stdout.write('\u0007')), // Ring the notification bell on test end
};

/**
 * Expects a StarkNet transaction to fail
 * @param {Promise<any>} transaction - The transaction that should fail
 * @param {string} [message] - The message returned from StarkNet
 */
// eslint-disable-next-line @typescript-eslint/no-explicit-any
export async function assertError(transaction: Promise<any>, errorMessage: string = 'Transaction rejected.') {
  try {
    await transaction;
    expect.fail('Transaction should fail');
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
  } catch (err: any) {
    expect(err.message).to.include(errorMessage);
  }
}

/**
 * Logs the error on call fail.
 * Sometimes the error are not correctly displayed. This helper can help debug hard to find errors
 * @param {() => Promise<void>} fn - The function to test
 */
export async function tryCatch(fn: () => Promise<void>) {
  try {
    await fn();
  } catch (e) {
    console.error(e);
    expect.fail('Test failed');
  }
}

/**
 * Gets the events emitted by a specific contract
 * @param {Event[]} events - The events
 * @param {string} contractAddress - The contract address
 */
export const getContractEvents = (events: Event[], contractAddress: string) => {
  return events.filter(event => event.from_address === contractAddress);
};

/**
 * Gets the events matching a specific event name
 * @param {Event[]} events - The events
 * @param {string} message - The message
 */
export const getMessageEvents = (events: Event[], message: string) => {
  return events.filter(event => event.keys.includes(hash.getSelectorFromName(message)));
};
