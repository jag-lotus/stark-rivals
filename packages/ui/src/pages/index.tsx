import { Center, Flex } from "@chakra-ui/react";
import type { NextPage } from "next";
import { useState } from "react";
import { CreateJoinGame } from "~/components/CreateJoinGame";
import { Game } from "~/components/Game";
import { Header } from "~/components/Header";

const Home: NextPage = () => {
  const [currentGameId, setCurrentGameId] = useState<string | undefined>();

  return (
    <Flex w="100vw" h="100vh" flexDir="column">
      <Header />
      <Center flex="1">
        {currentGameId ? (
          <Game />
        ) : (
          <CreateJoinGame onJoinGame={setCurrentGameId} />
        )}
      </Center>
    </Flex>
  );
};

export default Home;
