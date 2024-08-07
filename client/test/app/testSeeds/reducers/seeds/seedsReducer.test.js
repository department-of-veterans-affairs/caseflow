/* eslint-disable line-comment-position */
import seedsReducer from 'app/testSeeds/reducers/seeds/seedsReducer';
import { ACTIONS } from 'app/testSeeds/reducers/seeds/seedsActionTypes';

describe('seedsReducer function declaration', () => {

  let initialState = {
    seeds: [],
    displayBanner: false
  };

  it('should initialize the reducer with initialState', () => {
    const state = seedsReducer(undefined, {});
    expect(state).toEqual(initialState);
  });
});

describe('Seed reducer', () => {

  let seed = {
    "seed_count": 1,
    "days_ago": 12,
    "judge_css_id": "keeling",
    "seed_type": "ama-aod-hearing-seeds"
  };

  let seed1 = {
    "seed_count": 1,
    "days_ago": 12,
    "judge_css_id": "keeling",
    "seed_type": "ama-aod-hearing-seeds"
  };

  let seed2 = {
    "seed_count": 1,
    "days_ago": 20,
    "judge_css_id": "keeling1",
    "seed_type": "ama-aod-hearing-seeds"
  };

  let seed3 = {
    "seed_count": 1,
    "days_ago": 25,
    "judge_css_id": "keeling2",
    "seed_type": "ama-aod-hearing-seeds"
  };

  let initialState = {
    seeds: [seed1, seed2, seed3],
    displayBanner: false
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('Should handle ADD_CUSTOM_SEED and REMOVE_CUSTOM_SEED action', () => {
    const action = {
      type: ACTIONS.ADD_CUSTOM_SEED,
      payload: {
        seed: seed
      }
    };

    const newState = seedsReducer(initialState, action);
    expect(newState.seeds).toContain(seed);
  });

  it('Should handle RESET_CUSTOM_SEEDS action', () => {
    const action = {
      type: ACTIONS.RESET_CUSTOM_SEEDS,
    };

    const expectedState = {
      ...initialState,
      seeds: []
    };

    const newState = seedsReducer(initialState, action);

    expect(newState).toEqual(expectedState);
  });

  it('Should set displayBanner to true when dispatched SAVE_CUSTOM_SEEDS action', () => {
    const action = {
      type: ACTIONS.SAVE_CUSTOM_SEEDS
    };

    const newState = seedsReducer(initialState, action);
    expect(newState.displayBanner).toBe(true);
  });

  it('should not modify the state for unknown action', () => {
    const action = { type: 'UNKNOWN_ACTION' };

    const newState = seedsReducer(initialState, action);
    expect(newState).toEqual(initialState);
  });

  it('should remove a custom seed when dispatche REMOVE_CUSTOM_SEED action', () => {
    const indexToRemove = 1;
    const action = {
      type: ACTIONS.REMOVE_CUSTOM_SEED,
      payload: {
        index: indexToRemove
      }
    };

    const newState = seedsReducer(initialState, action);
    expect(newState.seeds).toHaveLength(initialState.seeds.length - 1);
    expect(newState.seeds).not.toContain(initialState.seeds[indexToRemove]);
  });
});
