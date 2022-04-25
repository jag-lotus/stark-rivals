import { Box, Center, Flex, Text } from "@chakra-ui/react";
import React from "react";

interface SingleProps {
  lasers: number;
  rockets: number;
  selected?: boolean;
  onClick?: () => void;
}

export function Card({ lasers, rockets, selected, onClick }: SingleProps) {
  return (
    <Center
      onClick={onClick}
      cursor="pointer"
      w={40}
      h={200}
      m={10}
      p={4}
      border={selected ? "5px solid" : "1px solid"}
      borderColor={selected ? "blue.500" : "gray.500"}
      borderRadius={6}
      _hover={{
        borderColor: selected ? "blue.500" : "gray.800",
        shadow: "md",
      }}
    >
      <Flex flexDir="column">
        <Box>
          <Text fontSize="xl">L: {lasers.toString()}</Text>
        </Box>
        <Box>
          <Text fontSize="xl">R: {rockets.toString()}</Text>
        </Box>
      </Flex>
    </Center>
  );
}
