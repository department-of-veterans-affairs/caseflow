import * as actions from 'app/testSeeds/reducers/seeds/seedsActions';
import { ACTIONS } from 'app/testSeeds/reducers/seeds/seedsActionTypes';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/util/ApiUtil', () => ({
  get: jest.fn(),
  post: jest.fn()
}));

describe('seeds actions', () => {
  let seed = {
    "seed_count": 1,
    "days_ago": 12,
    "judge_css_id": "keeling",
    "seed_type": "ama-aod-hearing-seeds"
  };

  it('should create an action to set the custom seed', () => {
    const expectedAction = {
      type: ACTIONS.ADD_CUSTOM_SEED,
      payload: { seed }
    };

    const dispatch = jest.fn();

    actions.addCustomSeed(seed)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should remove the custom seed', () => {
    const index = 0;
    const expectedAction = {
      type: ACTIONS.REMOVE_CUSTOM_SEED,
      payload: { seed, index }
    };

    const dispatch = jest.fn();

    actions.removeCustomSeed(seed, index)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should reset the custom seed objects', () => {
    const expectedAction = {
      type: ACTIONS.RESET_CUSTOM_SEEDS
    };

    const dispatch = jest.fn();

    actions.resetCustomSeeds()(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should save action to set the custom seed', () => {
    ApiUtil.post.mockResolvedValueOnce({ data: 'Success' });

    const dispatch = jest.fn();

    actions.saveCustomSeeds([seed])(dispatch);
    expect(ApiUtil.post).toHaveBeenCalledWith(`/seeds/run-demo`, {
      data: [seed]
    });
  });
});
