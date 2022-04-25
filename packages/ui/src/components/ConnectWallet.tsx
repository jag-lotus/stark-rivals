import { Button } from "@chakra-ui/react";
import { useStarknet, InjectedConnector } from "@starknet-react/core";
import { useShortAddress } from "~/hooks/address";

export function ConnectWallet() {
  const { account, connect } = useStarknet();

  const shortAddress = useShortAddress({ address: account });

  if (account && shortAddress) {
    return <Button>{shortAddress}</Button>;
  }

  return (
    <Button onClick={() => connect(new InjectedConnector())}>Connect</Button>
  );
}
