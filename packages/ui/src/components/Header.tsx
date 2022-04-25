import { Box, Flex, Spacer } from "@chakra-ui/react";
import React from "react";
import { ConnectWallet } from "./ConnectWallet";

export function Header() {
  return (
    <Flex p={8} w="100%">
      <Box></Box>
      <Spacer />
      <Box>
        <ConnectWallet />
      </Box>
    </Flex>
  );
}
