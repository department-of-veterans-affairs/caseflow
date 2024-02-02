import * as redux from 'redux';
import React from 'react';
import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import { render } from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import {
  mockBatchLevers,
  mockDocketDistributionPriorLevers,
  mockAffinityDaysLevers,
  mockStaticLevers,
  mockDocketTimeGoalsLevers,
  mockHistoryPayload,
  mockReturnedOption
} from 'test/data/adminCaseDistributionLevers';
import thunk from 'redux-thunk';
import * as leverActions from 'app/caseDistribution/reducers/levers/leversActions';

let mockInitialLevers = {
  static: mockStaticLevers,
  batch: mockBatchLevers,
  affinity: mockAffinityDaysLevers,
  docket_distribution_prior: mockDocketDistributionPriorLevers,
  docket_time_goal: mockDocketTimeGoalsLevers,
};

jest.mock('app/caseDistribution/utils', () => ({
  createUpdatedLeversWithValues: jest.fn(() => (mockInitialLevers)),
  leverErrorMessageExists: jest.fn(),
  findOption: jest.fn(() => (mockReturnedOption)),
  createCombinationValue: jest.fn(),
  formatLeverHistory: jest.fn(() => (mockHistoryPayload))
}));

describe('Lever reducer', () => {

  let initialState = {
    levers: mockInitialLevers, // Sample initial levers state
    backendLevers: [{ item: 'item1' }, { item: 'item2' }], // Sample backendLevers state
    leversErrors: [],
  };

  const getStore = () => redux.createStore(
    rootReducer,
    redux.applyMiddleware(thunk)
  );

  let leversLoadPayload = {
    batch: mockBatchLevers,
    docket_distribution_prior: mockDocketDistributionPriorLevers,
    affinity: mockAffinityDaysLevers
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it.skip('Calls Load Levers from LeversReducer', () => {
    let spyLoad = jest.spyOn(leverActions, 'loadLevers');
    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.setUserIsAcdAdmin(false));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyLoad).toBeCalledWith(leversLoadPayload);
  });

  it('Should handle LOAD_HISTORY action', () => {

    const action = {
      type: ACTIONS.LOAD_HISTORY,
      payload: {
        historyList: mockHistoryPayload
      }
    };

    const expectedState = {
      ...initialState,
      historyList: mockHistoryPayload
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).not.toEqual(initialState);
  });

  it.skip('Calls Update Text Lever from LeversReducer', () => {

    let spyUpdateText = jest.spyOn(leverActions, 'updateTextLever');

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.updateTextLever('batch', 'test-lever', 'testValue'));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyUpdateText).toBeCalledWith('batch', 'test-lever', 'testValue');
  });

  it.skip('Calls Update Combination Lever from LeversReducer', () => {

    let spyUpdateCombination = jest.spyOn(leverActions, 'updateCombinationLever');

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.updateCombinationLever(
      'docket_distribution_prior',
      'ama_hearings_start_distribution_prior_to_goals',
      '30',
      false)
    );

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyUpdateCombination).toBeCalledWith(
      'docket_distribution_prior',
      'ama_hearings_start_distribution_prior_to_goals',
      '30',
      false
    );
  });

  it.skip('Should handle UPDATE_RADIO_LEVER action', () => {
    const action = {
      type: ACTIONS.UPDATE_RADIO_LEVER,
      payload: {
        leverGroup: 'affinity',
        leverItem: 'ama_hearing_case_affinity_days',
        value: 'option_1',
        optionValue: 89,
      }
    };

    let updatedLever = mockAffinityDaysLevers.filter((obj) => {
      return obj.item === action.payload.leverItem;
    });

    const expectedState = {
      ...initialState,
      levers: {
        affinity: {
          ...mockAffinityDaysLevers,
          updatedLever
        }
      },
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).not.toEqual(initialState);
  });

  it('Should handle HIDE_BANNER action', () => {

    const action = {
      type: ACTIONS.HIDE_BANNER,
    };

    const expectedState = {
      ...initialState,
      levers: mockInitialLevers,
      displayBanner: false,
      errors: []
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
  });

  it.skip('should handle ADD_LEVER_VALIDATION_ERRORS and REMOVE_LEVER_VALIDATION_ERRORS action', () => {

    const actionForError = {
      type: ACTIONS.ADD_LEVER_VALIDATION_ERRORS,
      payload: {
        errors: ['error1', 'error2'] // Sample errors payload
      }
    };

    const expectedErrorState = {
      ...initialState,
      leversErrors: actionForError.payload.errors,
    };

    const newStateError = leversReducer(initialState, actionForError);

    expect(newStateError).toEqual(expectedErrorState);
    expect(newStateError).not.toEqual(initialState);

    const actionToClearError = {
      type: ACTIONS.REMOVE_LEVER_VALIDATION_ERRORS,
      payload: {
        errors: ['error1', 'error2']
      }
    };

    const expectedFixedState = {
      ...initialState,
      leversErrors: [],
    };

    const newStateFixed = leversReducer(initialState, actionToClearError);

    expect(newStateFixed).toEqual(expectedFixedState);
    expect(newStateFixed).toEqual(initialState);

  });

  it('should handle RESET_ALL_VALIDATION_ERRORS action', () => {

    const actionForError = {
      type: ACTIONS.ADD_LEVER_VALIDATION_ERRORS,
      payload: {
        errors: ['error1', 'error2'] // Sample errors payload
      }
    };

    const expectedErrorState = {
      ...initialState,
      leversErrors: actionForError.payload.errors,
    };

    const newStateError = leversReducer(initialState, actionForError);

    expect(newStateError).toEqual(expectedErrorState);
    expect(newStateError).not.toEqual(initialState);

    const actionToClearError = {
      type: ACTIONS.RESET_ALL_VALIDATION_ERRORS,
    };

    const expectedFixedState = {
      ...initialState,
      leversErrors: [],
    };

    const newStateFixed = leversReducer(initialState, actionToClearError);

    expect(newStateFixed).toEqual(expectedFixedState);
    expect(newStateFixed).toEqual(initialState);

  });

  it('should handle SAVE_LEVERS action', () => {

    const action = {
      type: ACTIONS.SAVE_LEVERS,
      payload: {
        errors: ['error1', 'error2']
      }
    };

    const expectedState = {
      ...initialState,
      displayBanner: true,
      errors: action.payload.errors
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).not.toEqual(initialState);
  });

  it('should handle REVERT_LEVERS action', () => {

    const action = {
      type: ACTIONS.REVERT_LEVERS,
    };

    const expectedState = {
      ...initialState,
      levers: mockInitialLevers
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).toEqual(initialState);
  });
});
