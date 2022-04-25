import type { AppProps } from "next/app";
import NextHead from "next/head";
import { InjectedConnector, StarknetProvider } from "@starknet-react/core";
import { ChakraProvider } from "@chakra-ui/react";

function MyApp({ Component, pageProps }: AppProps) {
  const connectors = [new InjectedConnector()];

  return (
    <ChakraProvider>
      <StarknetProvider autoConnect connectors={connectors}>
        <NextHead>
          <title>Stark Rivals</title>
        </NextHead>
        <Component {...pageProps} />
      </StarknetProvider>
    </ChakraProvider>
  );
}

export default MyApp;
