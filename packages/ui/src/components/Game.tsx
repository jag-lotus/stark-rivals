import {
  Box,
  Button,
  Center,
  Flex,
  HStack,
  Input,
  Modal,
  ModalBody,
  ModalCloseButton,
  ModalContent,
  ModalHeader,
  ModalOverlay,
  Spacer,
  Text,
  VStack,
} from "@chakra-ui/react";
import React, { useMemo } from "react";
import { useGameState } from "~/hooks/game";
import { Card } from "./Card";

export function Game() {
  const {
    thisPlayer,
    otherPlayer,
    selectPlayerCard,
    selectedCard: selectedCardId,
    getThisPlayerCard,
  } = useGameState();

  const selectedCard = useMemo(() => {
    return getThisPlayerCard(selectedCardId);
  }, [getThisPlayerCard, selectedCardId]);

  return (
    <React.Fragment>
      <Flex flexDir="column">
        <VStack>
          <Flex flexDir="row" w="100%">
            <Box bg="red.100">
              <Text>Rival: 0 LP - 10 B</Text>
            </Box>
            <Spacer />
          </Flex>
          <Flex bg="red.50">
            {otherPlayer.cards.map((card, index) => (
              <Card key={index} lasers={card.lasers} rockets={card.rockets} />
            ))}
          </Flex>
        </VStack>
        <Spacer my={10} />
        <VStack>
          <Flex bg="green.50">
            {thisPlayer.cards.map((card, index) => (
              <Card
                key={index}
                lasers={card.lasers}
                rockets={card.rockets}
                onClick={() => selectPlayerCard(card.id)}
              />
            ))}
          </Flex>
          <Flex flexDir="row" w="100%">
            <Spacer />
            <Box bg="green.100">
              <Text>You: 0 LP - 10 B</Text>
            </Box>
          </Flex>
        </VStack>
      </Flex>
      <Modal isOpen={!!selectedCard} onClose={() => selectPlayerCard()}>
        <ModalOverlay />
        <ModalContent>
          <ModalHeader>Play</ModalHeader>
          <ModalCloseButton />
          <ModalBody>
            <Flex flexDir="row">
              <Box>
                {selectedCard && (
                  <Card
                    lasers={selectedCard.lasers}
                    rockets={selectedCard.rockets}
                  />
                )}
              </Box>
              <Center flexGrow={1} h="100%">
                <Flex flexDir="column">
                  <Box mb={10}>
                    <Text>Available batteries:</Text>
                    <Text fontSize={30}>10</Text>
                  </Box>
                  <Box>
                    <Input placeholder="batteries" />
                  </Box>
                  <Box>
                    <Button>Attack</Button>
                  </Box>
                </Flex>
              </Center>
            </Flex>
          </ModalBody>
        </ModalContent>
      </Modal>
    </React.Fragment>
  );
}
