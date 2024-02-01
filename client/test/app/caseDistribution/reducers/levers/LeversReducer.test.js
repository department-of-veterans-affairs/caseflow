import * as redux from 'redux';
import React from 'react';
import { render, waitFor } from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import { testingBatchLevers,
  testingBatchLeversUpdatedToSave,
  testingDocketDistributionPriorLevers,
  testingAffinityDaysLevers } from '../../../../data/adminCaseDistributionLevers';
import thunk from 'redux-thunk';
import * as leverActions from 'app/caseDistribution/reducers/levers/leversActions';
import ApiUtil from 'app/util/ApiUtil';

describe('Lever reducer', () => {

  const getStore = () => redux.createStore(
    rootReducer,
    redux.applyMiddleware(thunk)
  );

  let leversLoadPayload = {
    batch: testingBatchLevers,
    docket_distribution_prior: testingDocketDistributionPriorLevers,
    affinity: testingAffinityDaysLevers
  };

  let leversSavePayload = {
    batch: testingBatchLeversUpdatedToSave,
    docket_distribution_prior: testingDocketDistributionPriorLevers,
    affinity: testingAffinityDaysLevers
  };

  afterEach(() => {
    jest.clearAllMocks();
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

  it('Calls Reset All Lever Errors from LeversReducer', () => {

    let spyAddLeverErrors = jest.spyOn(leverActions, 'addLeverErrors');
    let spyResetErrors = jest.spyOn(leverActions, 'resetAllLeverErrors');

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    store.dispatch(leverActions.addLeverErrors(['TEST ERROR']));
    store.dispatch(leverActions.resetAllLeverErrors());

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyAddLeverErrors).toBeCalledWith(['TEST ERROR']);
    expect(spyResetErrors).toBeCalled();
  });

  it('Calls Reset Levers from LeversReducer', async () => {

    let spyResetLevers = jest.spyOn(leverActions, 'resetLevers');
    let spyResetAPICall = jest.spyOn(ApiUtil, 'get').mockReturnValue({
      body: leversLoadPayload
    });

    const store = getStore();

    store.dispatch(leverActions.loadLevers(leversLoadPayload));
    await store.dispatch(leverActions.resetLevers());

    render(
      <Provider store={store}>
        <BatchSize />
      </Provider>
    );
    expect(spyResetLevers).toBeCalled();
    expect(spyResetAPICall).toBeCalled();
  });
});
