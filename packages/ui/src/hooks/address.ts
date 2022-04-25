export function useShortAddress({ address }: { address?: string }) {
  if (address && address.length > 10) {
    return `${address.slice(0, 6)}...${address.slice(-4)}`;
  }
  return;
}
