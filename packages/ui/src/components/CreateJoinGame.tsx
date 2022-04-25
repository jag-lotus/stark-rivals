import { Box, Button, Flex, Input, VStack } from "@chakra-ui/react";
import React from "react";

interface CreateJoinGameProps {
  onJoinGame: (gameId: string) => void;
}

export function CreateJoinGame({ onJoinGame }: CreateJoinGameProps) {
  return (
    <Box
      border="1px solid"
      borderColor="grey.500"
      p={8}
      borderRadius={8}
      backgroundColor="gray.100"
      shadow="lg"
    >
      <VStack>
        <Box>
          <Flex>
            <Input placeholder="Game ID" />
            <Button ml={2}>Join Game</Button>
          </Flex>
        </Box>
        <Box pt={8}>
          <Button onClick={() => onJoinGame("1")}>Create Game</Button>
        </Box>
      </VStack>
    </Box>
  );
}
