/* eslint-disable line-comment-position */
import seedsReducer from 'app/testSeeds/reducers/seeds/seedsReducer';
import { ACTIONS } from 'app/testSeeds/reducers/seeds/seedsActionTypes';

describe('Seed reducer', () => {

  let initialState = {
    seeds: [],
    displayBanner: false
  };

  let seed = {
    "seed_count": 1,
    "days_ago": 12,
    "judge_css_id": "keeling",
    "seed_type": "ama-aod-hearing-seeds"
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

    const expectedState = {
      ...initialState,
      seeds: [action.payload.seed]
    };

    const newState = seedsReducer(initialState, action);

    expect(newState).toEqual(expectedState);

    const removeAction = {
      type: ACTIONS.REMOVE_CUSTOM_SEED,
      payload: {
        seed: seed,
        index: 0
      }
    };

    const expectedRemoveState = {
      ...initialState,
      seeds: []
    };

    const newStateFixed = seedsReducer(initialState, removeAction);

    expect(newStateFixed).toEqual(expectedRemoveState);
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
});
