import * as actions from 'app/caseDistribution/reducers/levers/leversActions';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import ApiUtil from 'app/util/ApiUtil';
import { levers, historyList } from '../../../../data/adminCaseDistributionLevers';

jest.mock('app/util/ApiUtil', () => ({
  get: jest.fn(),
  post: jest.fn()
}));

describe('levers actions', () => {
  it('should create an action to set user as ACD admin', () => {
    const isUserAcdAdmin = true;
    const expectedAction = {
      type: ACTIONS.SET_USER_IS_ACD_ADMIN,
      payload: { isUserAcdAdmin }
    };

    const dispatch = jest.fn();

    actions.setUserIsAcdAdmin(isUserAcdAdmin)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to load levers', () => {
    const expectedAction = {
      type: ACTIONS.LOAD_LEVERS,
      payload: { levers }
    };

    const dispatch = jest.fn();

    actions.loadLevers(levers)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to load lever history', () => {
    const expectedAction = {
      type: ACTIONS.LOAD_HISTORY,
      payload: { historyList }
    };

    const dispatch = jest.fn();

    actions.loadHistory(historyList)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to reset levers', async () => {
    const mockResponse = { body: { levers } };

    ApiUtil.get.mockResolvedValue(mockResponse);

    const expectedAction = {
      type: ACTIONS.LOAD_LEVERS,
      payload: { levers }
    };

    const dispatch = jest.fn();

    await actions.resetLevers()(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to update a radio lever', () => {
    const leverIndex = 8;
    const lever = levers[leverIndex];
    const optionIndex = 1;
    const option = lever.options[optionIndex];

    const expectedAction = {
      type: ACTIONS.UPDATE_RADIO_LEVER,
      payload: {
        leverGroup: lever.lever_group,
        leverItem: lever.item,
        value: option.value,
        optionValue: option.text
      }
    };

    const dispatch = jest.fn();

    actions.updateRadioLever(lever.lever_group, lever.item, option.value, option.text)(dispatch);
    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to update a combination lever', () => {
    const leverIndex = 9;
    const lever = levers[leverIndex];

    const expectedAction = {
      type: ACTIONS.UPDATE_COMBINATION_LEVER,
      payload: {
        leverGroup: lever.lever_group,
        leverItem: lever.item,
        value: lever.value,
        toggleValue: lever.is_toggle_active
      }
    };

    const dispatch = jest.fn();

    actions.updateCombinationLever(lever.lever_group, lever.item, lever.value, lever.is_toggle_active)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to update a boolean lever', () => {
    const leverIndex = 0;
    const lever = levers[leverIndex];

    const expectedAction = {
      type: ACTIONS.UPDATE_BOOLEAN_LEVER,
      payload: {
        leverGroup: lever.lever_group,
        leverItem: lever.item,
        value: lever.value
      }
    };

    const dispatch = jest.fn();

    actions.updateBooleanLever(lever.lever_group, lever.item, lever.value)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to update a text lever', () => {
    const leverIndex = 0;
    const lever = levers[leverIndex];

    const expectedAction = {
      type: ACTIONS.UPDATE_TEXT_LEVER,
      payload: {
        leverGroup: lever.lever_group,
        leverItem: lever.item,
        value: lever.value
      }
    };

    const dispatch = jest.fn();

    actions.updateTextLever(lever.lever_group, lever.item, lever.value)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should create an action to update a number lever', () => {
    const leverIndex = 0;
    const lever = levers[leverIndex];
    const expectedAction = {
      type: ACTIONS.UPDATE_NUMBER_LEVER,
      payload: {
        leverGroup: lever.lever_group,
        leverItem: lever.item,
        value: lever.value
      }
    };

    const dispatch = jest.fn();

    actions.updateNumberLever(lever.lever_group, lever.item, lever.value)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should dispatch actions after saving levers', async () => {
    const mockResponse = {
      levers: [],
      errors: [],
      lever_history: []
    };

    ApiUtil.post.mockResolvedValueOnce({ body: mockResponse });

    const expectedActions = [
      { type: ACTIONS.LOAD_LEVERS, payload: { levers: mockResponse.levers } },
      { type: ACTIONS.SAVE_LEVERS, payload: { errors: mockResponse.errors } },
      { type: ACTIONS.LOAD_HISTORY, payload: { historyList: mockResponse.lever_history } }
    ];

    const dispatch = jest.fn();

    await actions.saveLevers(levers)(dispatch);

    expect(dispatch.mock.calls[0][0]).toEqual(expectedActions[0]);
    expect(dispatch.mock.calls[1][0]).toEqual(expectedActions[1]);
    expect(dispatch.mock.calls[2][0]).toEqual(expectedActions[2]);
  });

  it('should hide success banner', () => {
    const expectedAction = {
      type: ACTIONS.HIDE_BANNER
    };

    const dispatch = jest.fn();

    actions.hideSuccessBanner()(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should add lever errors', () => {
    const errors = 'errors';
    const expectedAction = {
      type: ACTIONS.ADD_LEVER_VALIDATION_ERRORS,
      payload: { errors }
    };

    const dispatch = jest.fn();

    actions.addLeverErrors(errors)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should remove lever errors', () => {
    const leverIndex = 0;
    const lever = levers[leverIndex];
    const expectedAction = {
      type: ACTIONS.REMOVE_LEVER_VALIDATION_ERRORS,
      payload: { leverItem: lever.item }
    };

    const dispatch = jest.fn();

    actions.removeLeverErrors(lever.item)(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });

  it('should reset all levers', () => {
    const expectedAction = {
      type: ACTIONS.RESET_ALL_VALIDATION_ERRORS
    };

    const dispatch = jest.fn();

    actions.resetAllLeverErrors()(dispatch);

    expect(dispatch).toHaveBeenCalledWith(expectedAction);
  });
});
