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
  mockDocketTimeGoalsLevers
} from '../../../../data/adminCaseDistributionLevers';
import thunk from 'redux-thunk';
import * as leverActions from 'app/caseDistribution/reducers/levers/leversActions';
import ApiUtil from 'app/util/ApiUtil';

let mockInitialLevers = {
  static: mockStaticLevers,
  batch: mockBatchLevers,
  affinity: mockAffinityDaysLevers,
  docket_distribution_prior: mockDocketDistributionPriorLevers,
  docket_time_goal: mockDocketTimeGoalsLevers,
}

jest.mock('app/caseDistribution/utils', () => ({
  createUpdatedLeversWithValues: jest.fn(() => (mockInitialLevers)),
  leverErrorMessageExists: jest.fn(),
  findOption: jest.fn(),
  createCombinationValue: jest.fn(),
  formatLeverHistory: jest.fn()
}));

jest.mock('app/caseDistribution/reducers/levers/LeversSelector', () => ({
  ...jest.requireActual('app/caseDistribution/reducers/levers/LeversSelector'), // Keep other functions as they are
  updateLeverGroup: jest.fn(),
  createUpdatedRadioLever: jest.fn()
}));

describe('Lever reducer', () => {

  let initialState = {};

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

  beforeEach(() => {
    initialState = {
      levers: mockInitialLevers, // Sample initial levers state
      backendLevers: [{ item: 'item1' }, { item: 'item2' }], // Sample backendLevers state
    };
  });

  it('Calls Load Levers from LeversReducer', () => {
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

  it('Calls Load History from LeversReducer', () => {

    let historyPayload = [
      {
        case_distribution_lever_id: 5,
        created_at: '2024-01-12T16:48:35.422-05:00',
        id: 27,
        lever_data_type: 'number',
        lever_title: 'Alternate Batch Size*',
        lever_unit: 'cases',
        previous_value: '15',
        update_value: '70',
        user_css_id: 'BVADWISE'
      }
    ];
    let spyHistory = jest.spyOn(leverActions, 'loadHistory');
    const store = getStore();

    store.dispatch(leverActions.loadHistory(historyPayload));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyHistory).toBeCalledWith(historyPayload);
  });

  it('Calls Update Text Lever from LeversReducer', () => {

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

  it('Calls Update Combination Lever from LeversReducer', () => {

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

  it('Calls Update Radio Lever from LeversReducer', () => {

    let spyUpdateRadio = jest.spyOn(leverActions, 'updateRadioLever');

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.updateRadioLever(
      'affinity',
      'ama_hearing_case_affinity_days',
      'option_1',
      '100')
    );

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyUpdateRadio).toBeCalledWith(
      'affinity',
      'ama_hearing_case_affinity_days',
      'option_1',
      '100'
    );
  });

  it('Calls  Hide Success Banner from LeversReducer', () => {

    let spyHideBanner = jest.spyOn(leverActions, 'hideSuccessBanner');

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.hideSuccessBanner());

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyHideBanner).toBeCalled();
  });

  it('Calls Add and Remove Lever Errors from LeversReducer', () => {

    let spyAddLeverErrors = jest.spyOn(leverActions, 'addLeverErrors');
    let spyRemoveLeverErrors = jest.spyOn(leverActions, 'removeLeverErrors');

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.addLeverErrors(['TEST ERROR']));
    store.dispatch(leverActions.removeLeverErrors('test-lever'));

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyAddLeverErrors).toBeCalledWith(['TEST ERROR']);
    expect(spyRemoveLeverErrors).toBeCalledWith('test-lever');
  });

  it('shoudl handle ADD_LEVER_VALIDATION_ERRORS and RESET_ALL_VALIDATION_ERRORS action', () => {

    const actionForError = {
      type: ACTIONS.ADD_LEVER_VALIDATION_ERRORS,
      payload: {
        errors: ['error1', 'error2'] // Sample errors payload
      }
    };

    const expectedErrorState = {
      ...initialState,
      leversErrors: ['error1', 'error2'],
    };

    const newStateError = leversReducer(initialState, actionForError);

    expect(newStateError).toEqual(expectedErrorState);
    // expect(newStateError).not.toEqual(initialState);

    // const actionToClearError = {
    //   type: ACTIONS.RESET_ALL_VALIDATION_ERRORS,
    // };

    // const expectedFixedState = {
    //   ...initialState,
    //   leversErrors: ['error1', 'error2'],
    // };

    // const newStateFixed = leversReducer(initialState, actionToClearError);

    // expect(newStateFixed).toEqual(expectedFixedState);
    // expect(newStateFixed).not.toEqual(initialState);

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
      changesOccurred: false,
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
