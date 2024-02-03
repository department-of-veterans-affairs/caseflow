import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import {
  mockBatchLevers,
  mockDocketDistributionPriorLevers,
  mockAffinityDaysLevers,
  mockStaticLevers,
  mockDocketTimeGoalsLevers,
  mockHistoryPayload,
  mockReturnedOption,
  mockTextLeverReturn,
  mockDocketDistributionPriorLeversReturn,
  mockmockAffinityDaysLeversReturn
} from 'test/data/adminCaseDistributionLevers';

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
  createCombinationValue: jest.fn(() => (40)),
  createUpdatedCombinationLever: jest.fn(() => (mockDocketDistributionPriorLeversReturn)),
  createUpdatedRadioLever: jest.fn(() => (mockmockAffinityDaysLeversReturn)),
  createUpdatedLever: jest.fn(() => (mockTextLeverReturn)),
  formatLeverHistory: jest.fn(() => (mockHistoryPayload))
}));

describe('Lever reducer', () => {

  let initialState = {
    levers: mockInitialLevers, // Sample initial levers state
    backendLevers: [{ item: 'item1' }, { item: 'item2' }], // Sample backendLevers state
    leversErrors: [],
    isUserAcdAdmin: false,
  };

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('Should handle LOAD_LEVERS action', () => {
    const action = {
      type: ACTIONS.LOAD_LEVERS,
      payload: {
        levers: mockInitialLevers
      }
    };

    const expectedState = {
      ...initialState,
      levers: mockInitialLevers
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
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

  it('Should handle SET_USER_IS_ACD_ADMIN action', () => {

    const action = {
      type: ACTIONS.SET_USER_IS_ACD_ADMIN,
      payload: {
        isUserAcdAdmin: true
      }
    };

    const expectedState = {
      ...initialState,
      isUserAcdAdmin: true
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).not.toEqual(initialState);
  });

  //Below Test seems to work correctly, but not sure how to format expected state to match new value
  it.skip('should handle UPDATE_TEXT_LEVER action', () => {
    const action = {
      type: ACTIONS.UPDATE_TEXT_LEVER,
      payload: {
        leverGroup: 'batch',
        leverItem: 'test-lever-text-type',
        value: 78
      }
    };

    const expectedState = {
      ...initialState,
      //Input here to check that value for test-lever-text-type is value of 78
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).not.toEqual(initialState);
  });

    //Below test seems to call the action correctly for coverage, not sure about expectedState value.
  it.skip('should handle UPDATE_COMBINATION_LEVER action', () => {
    const action = {
      type: ACTIONS.UPDATE_COMBINATION_LEVER,
      payload: {
        leverGroup: 'docket_distribution_prior',
        leverItem: 'ama_hearings_start_distribution_prior_to_goals',
        value: 40
      }
    };

    const expectedState = {
      ...initialState,
      //Input here to check that value for test-lever-text-type is value of 40
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
    expect(newState).not.toEqual(initialState);
  });

  //Still needs to be completed
  it.skip('should handle UPDATE_RADIO_LEVER action', () => {
    const action = {
      type: ACTIONS.UPDATE_RADIO_LEVER,
      payload: {
        leverGroup: 'affinity',
        leverItem: 'ama_hearing_case_affinity_days',
        value: 80
      }
    };

    const expectedState = {
      ...initialState,
      //Input here to check that value for test-lever-text-type is value of 78
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

  it('should handle ADD_LEVER_VALIDATION_ERRORS and REMOVE_LEVER_VALIDATION_ERRORS action', () => {

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
