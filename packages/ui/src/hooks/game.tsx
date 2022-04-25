import { useCallback, useReducer } from "react";
import { List } from "immutable";

interface Card {
  id: string;
  playedTurn?: number;
  lasers: number;
  rockets: number;
}

interface PlayerHand {
  cards: List<Card>;
}

interface GameState {
  selectedCard?: string;
  thisPlayer: PlayerHand;
  otherPlayer: PlayerHand;
}

const INITIAL_HAND: PlayerHand = {
  cards: List([
    { id: "0", lasers: 5, rockets: 3 },
    { id: "1", lasers: 6, rockets: 2 },
    { id: "2", lasers: 6, rockets: 4 },
    { id: "3", lasers: 2, rockets: 7 },
    { id: "4", lasers: 4, rockets: 3 },
    { id: "5", lasers: 4, rockets: 4 },
  ]),
};

const INITIAL_STATE: GameState = {
  thisPlayer: INITIAL_HAND,
  otherPlayer: INITIAL_HAND,
};

interface SelectCard {
  type: "selectCard";
  id?: string;
}

type Action = SelectCard;

function reducer(state: GameState, action: Action): GameState {
  if (action.type === "selectCard") {
    return { ...state, selectedCard: action.id };
  }
  return state;
}

interface UseGameState {
  thisPlayer: PlayerHand;
  otherPlayer: PlayerHand;
  selectedCard?: string;

  getThisPlayerCard: (id?: string) => Card | undefined;

  selectPlayerCard: (id?: string) => void;
}

export function useGameState(): UseGameState {
  const [state, dispatch] = useReducer(reducer, INITIAL_STATE);

  const selectPlayerCard = useCallback(
    (id?: string) => {
      dispatch({ type: "selectCard", id });
    },
    [dispatch]
  );

  const getThisPlayerCard = useCallback(
    (id?: string) => {
      if (!id) return;
      return state.thisPlayer.cards.find((card) => card.id == id);
    },
    [state.thisPlayer.cards]
  );

  return {
    thisPlayer: state.thisPlayer,
    otherPlayer: state.otherPlayer,
    selectedCard: state.selectedCard,
    selectPlayerCard,
    getThisPlayerCard,
  };
}
