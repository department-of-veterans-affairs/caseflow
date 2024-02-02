import * as redux from 'redux';
import React from 'react';
import leversReducer from 'app/caseDistribution/reducers/levers/leversReducer';
import { ACTIONS } from 'app/caseDistribution/reducers/levers/leversActionTypes';
import { render, waitFor } from '@testing-library/react';
import BatchSize from 'app/caseDistribution/components/BatchSize';
import { Provider } from 'react-redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import {
  testingBatchLevers,
  testingBatchLeversUpdatedToSave,
  testingDocketDistributionPriorLevers,
  testingAffinityDaysLevers
} from '../../../../data/adminCaseDistributionLevers';
import thunk from 'redux-thunk';
import * as leverActions from 'app/caseDistribution/reducers/levers/leversActions';
import ApiUtil from 'app/util/ApiUtil';

jest.mock('app/caseDistribution/utils', () => ({
  createUpdatedLeversWithValues: jest.fn(() => ({
    static: [
      {
        id: 1,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.126-05:00',
        data_type: 'number',
        description: "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.",
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'maximum_direct_review_proportion',
        lever_group: 'static',
        lever_group_order: 1000,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'Maximum Direct Review Proportion',
        unit: '%',
        updated_at: '2024-01-24T11:52:10.126-05:00',
        value: '0.8',
        backendValue: '0.8'
      },
      {
        id: 2,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.132-05:00',
        data_type: 'number',
        description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'minimum_legacy_proportion',
        lever_group: 'static',
        lever_group_order: 1001,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'Minimum Legacy Proportion',
        unit: '%',
        updated_at: '2024-01-24T11:52:10.132-05:00',
        value: '0.2',
        backendValue: '0.2'
      },
      {
        id: 3,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.137-05:00',
        data_type: 'number',
        description: 'Applied for docket balancing reflecting the likelihood that NODs will advance to a Form 9.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'nod_adjustment',
        lever_group: 'static',
        lever_group_order: 1002,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'NOD Adjustment',
        unit: '%',
        updated_at: '2024-01-24T11:52:10.137-05:00',
        value: '0.9',
        backendValue: '0.9'
      },
      {
        id: 4,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.143-05:00',
        data_type: 'boolean',
        description: 'Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'bust_backlog',
        lever_group: 'static',
        lever_group_order: 1003,
        max_value: null,
        min_value: null,
        options: null,
        title: 'Priority Bust Backlog',
        unit: '',
        updated_at: '2024-01-24T11:52:10.143-05:00',
        value: 'true',
        backendValue: 'true'
      }
    ],
    batch: [
      {
        id: 6,
        algorithms_used: [
          'docket',
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.152-05:00',
        data_type: 'number',
        description: 'Sets case-distribution batch size for judges with attorney teams. The value for this data element is per attorney.',
        is_disabled_in_ui: false,
        is_toggle_active: true,
        item: 'batch_size_per_attorney',
        lever_group: 'batch',
        lever_group_order: 2001,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'Batch Size Per Attorney*',
        unit: 'cases',
        updated_at: '2024-01-24T11:52:10.152-05:00',
        value: '3',
        backendValue: '3'
      },
      {
        id: 7,
        algorithms_used: [
          'docket',
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.157-05:00',
        data_type: 'number',
        description: 'Sets the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used as equal to or less than)',
        is_disabled_in_ui: false,
        is_toggle_active: true,
        item: 'request_more_cases_minimum',
        lever_group: 'batch',
        lever_group_order: 2002,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'Request More Cases Minimum*',
        unit: 'cases',
        updated_at: '2024-01-31T19:33:20.727-05:00',
        value: '18',
        backendValue: '18'
      },
      {
        id: 5,
        algorithms_used: [
          'docket',
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.147-05:00',
        data_type: 'number',
        description: 'Sets case-distribution batch size for judges who do not have their own attorney teams.',
        is_disabled_in_ui: false,
        is_toggle_active: true,
        item: 'alternative_batch_size',
        lever_group: 'batch',
        lever_group_order: 2000,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'Alternate Batch Size*',
        unit: 'cases',
        updated_at: '2024-01-31T20:28:26.163-05:00',
        value: '12',
        backendValue: '12'
      }
    ],
    affinity: [
      {
        id: 8,
        algorithms_used: [
          'docket'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.162-05:00',
        data_type: 'radio',
        description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_hearing_case_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3000,
        max_value: 100,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 0,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days',
            min_value: 0,
            max_value: 100
          },
          {
            item: 'infinite',
            value: 'infinite',
            text: 'Always distribute to current judge'
          },
          {
            item: 'omit',
            value: 'omit',
            text: 'Omit variable from distribution rules'
          }
        ],
        title: 'AMA Hearing Case Affinity Days',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.162-05:00',
        value: 'value',
        currentValue: 0,
        backendValue: 0
      },
      {
        id: 9,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.167-05:00',
        data_type: 'radio',
        description: 'Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the most-recent hearing judge before distributing the appeal to any available judge.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_hearing_case_aod_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3001,
        max_value: 100,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 0,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days'
          },
          {
            item: 'infinite',
            data_type: '',
            value: 'infinite',
            text: 'Always distribute to current judge',
            unit: ''
          },
          {
            item: 'omit',
            data_type: '',
            value: 'omit',
            text: 'Omit variable from distribution rules',
            unit: ''
          }
        ],
        title: 'AMA Hearing Case AOD Affinity Days',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.167-05:00',
        value: 'value',
        currentValue: 0,
        backendValue: 0
      },
      {
        id: 10,
        algorithms_used: [
          'docket',
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.173-05:00',
        data_type: 'radio',
        description: 'Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with a hearing held.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'cavc_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3002,
        max_value: 100,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 21,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days'
          },
          {
            item: 'infinite',
            value: 'infinite',
            text: 'Always distribute to current judge'
          },
          {
            item: 'omit',
            value: 'omit',
            text: 'Omit variable from distribution rules'
          }
        ],
        title: 'CAVC Affinity Days*',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.173-05:00',
        value: 'value',
        currentValue: 21,
        backendValue: 21
      },
      {
        id: 11,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.178-05:00',
        data_type: 'radio',
        description: 'Sets the number of days appeals returned from CAVC that are also AOD respect the affinity to the deciding judge. This is not applicable for legacy apeals for which the deciding judge conducted the most recent hearing.',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'cavc_aod_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3003,
        max_value: null,
        min_value: null,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 21,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days'
          },
          {
            item: 'infinite',
            value: 'infinite',
            text: 'Always distribute to current judge'
          },
          {
            item: 'omit',
            value: 'omit',
            text: 'Omit variable from distribution rules'
          }
        ],
        title: 'CAVC AOD Affinity Days',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.178-05:00',
        value: 'value',
        currentValue: 21,
        backendValue: 21
      },
      {
        id: 13,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.189-05:00',
        data_type: 'radio',
        description: 'Sets the number of days legacy remand Returned appeals that are also AOD (and may or may not have been CAVC at one time) respect the affinity before distributing the appeal to any available jduge. Affects appeals with hearing held when the remanding judge is not the hearing judge, or any legacy AOD + AOD appeal with no hearing held (whether or not it had been CAVC at one time).',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'aoj_aod_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3005,
        max_value: 100,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 14,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days'
          },
          {
            item: 'infinite',
            data_type: '',
            value: 'infinite',
            text: 'Always distribute to current judge',
            unit: ''
          },
          {
            item: 'omit',
            data_type: '',
            value: 'omit',
            text: 'Omit variable from distribution rules',
            unit: ''
          }
        ],
        title: 'AOJ AOD Affinity Days',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.189-05:00',
        value: 'value',
        currentValue: 14,
        backendValue: 14
      },
      {
        id: 14,
        algorithms_used: [
          'docket'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.195-05:00',
        data_type: 'radio',
        description: 'Sets the number of days AOJ appeals that were CAVC at some time respect the affinity before the appeal is distributed to any available judge. This applies to any AOJ + CAVC appeal with no hearing held, or those with a hearing held when the remanding judge is not the hearing judge.',
        is_disabled_in_ui: true,
        is_toggle_active: true,
        item: 'aoj_cavc_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3006,
        max_value: 100,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 21,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days'
          },
          {
            item: 'infinite',
            data_type: '',
            value: 'infinite',
            text: 'Always distribute to current judge',
            unit: ''
          },
          {
            item: 'omit',
            data_type: '',
            value: 'omit',
            text: 'Omit variable from distribution rules',
            unit: ''
          }
        ],
        title: 'AOJ CAVC Affinity Days',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.195-05:00',
        value: 'value',
        currentValue: 21,
        backendValue: 21
      },
      {
        id: 12,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.184-05:00',
        data_type: 'radio',
        description: 'Sets the number of days an appeal respects the affinity to the deciding judge for Legacy AOJ Remand Returned appeals with no hearing held before distributing the appeal to any available judge.',
        is_disabled_in_ui: false,
        is_toggle_active: false,
        item: 'aoj_affinity_days',
        lever_group: 'affinity',
        lever_group_order: 3004,
        max_value: 100,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'number',
            value: 60,
            text: 'Attempt distribution to current judge for max of:',
            unit: 'days'
          },
          {
            item: 'infinite',
            data_type: '',
            value: 'infinite',
            text: 'Always distribute to current judge',
            unit: ''
          },
          {
            item: 'omit',
            data_type: '',
            value: 'omit',
            text: 'Omit variable from distribution rules',
            unit: ''
          }
        ],
        title: 'AOJ Affinity Days',
        unit: 'days',
        updated_at: '2024-01-25T22:58:51.826-05:00',
        value: 'value',
        currentValue: 60,
        backendValue: 60
      }
    ],
    docket_distribution_prior: [
      {
        id: 15,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.200-05:00',
        data_type: 'combination',
        description: '',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_hearings_start_distribution_prior_to_goals',
        lever_group: 'docket_distribution_prior',
        lever_group_order: 4000,
        max_value: null,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'boolean',
            value: true,
            text: 'This feature is turned on or off',
            unit: ''
          }
        ],
        title: 'AMA Hearings Start Distribution Prior to Goals',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.200-05:00',
        value: '770',
        currentValue: 'false-770',
        backendValue: 'false-770'
      },
      {
        id: 16,
        algorithms_used: [
          'docket'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.205-05:00',
        data_type: 'combination',
        description: '',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_direct_review_start_distribution_prior_to_goals',
        lever_group: 'docket_distribution_prior',
        lever_group_order: 4001,
        max_value: null,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'boolean',
            value: true,
            text: 'This feature is turned on or off',
            unit: ''
          }
        ],
        title: 'AMA Direct Review Start Distribution Prior to Goals',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.205-05:00',
        value: '365',
        currentValue: 'false-365',
        backendValue: 'false-365'
      },
      {
        id: 17,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.211-05:00',
        data_type: 'combination',
        description: '',
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_evidence_submission_start_distribution_prior_to_goals',
        lever_group: 'docket_distribution_prior',
        lever_group_order: 4002,
        max_value: null,
        min_value: 0,
        options: [
          {
            item: 'value',
            data_type: 'boolean',
            value: true,
            text: 'This feature is turned on or off',
            unit: ''
          }
        ],
        title: 'AMA Evidence Submission Start Distribution Prior to Goals',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.211-05:00',
        value: '550',
        currentValue: 'false-550',
        backendValue: 'false-550'
      }
    ],
    docket_time_goal: [
      {
        id: 18,
        algorithms_used: [
          'docket'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.216-05:00',
        data_type: 'number',
        description: null,
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_hearings_docket_time_goals',
        lever_group: 'docket_time_goal',
        lever_group_order: 4003,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'AMA Hearings Docket Time Goals',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.216-05:00',
        value: '365',
        backendValue: '365'
      },
      {
        id: 20,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.228-05:00',
        data_type: 'number',
        description: null,
        is_disabled_in_ui: true,
        is_toggle_active: false,
        item: 'ama_evidence_submission_docket_time_goals',
        lever_group: 'docket_time_goal',
        lever_group_order: 4005,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'AMA Evidence Submission Docket Time Goals',
        unit: 'days',
        updated_at: '2024-01-24T11:52:10.228-05:00',
        value: '123',
        backendValue: '123'
      },
      {
        id: 19,
        algorithms_used: [
          'proportion'
        ],
        control_group: null,
        created_at: '2024-01-24T11:52:10.222-05:00',
        data_type: 'number',
        description: null,
        is_disabled_in_ui: false,
        is_toggle_active: true,
        item: 'ama_direct_review_docket_time_goals',
        lever_group: 'docket_time_goal',
        lever_group_order: 4004,
        max_value: null,
        min_value: 0,
        options: null,
        title: 'AMA Direct Review Docket Time Goals',
        unit: 'days',
        updated_at: '2024-01-25T23:30:33.484-05:00',
        value: '50',
        backendValue: '50'
      }
    ]
  })),
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
  it('should handle SAVE_LEVERS action', () => {
    const initialState = {
      // Define initialState here
    };

    const action = {
      type: ACTIONS.SAVE_LEVERS,
      payload: {
        errors: ['error1', 'error2'] // Sample errors payload
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
  });

  it('should handle REVERT_LEVERS action', () => {
    const initialState = {
      // Define initialState here
      levers: {}, // Sample initial levers state
      backendLevers: [{ item: 'item1' }, { item: 'item2' }], // Sample backendLevers state
    };

    const action = {
      type: ACTIONS.REVERT_LEVERS,
    };

    const expectedState = {
      ...initialState,
      levers: {
        static: [
          {
            id: 1,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.126-05:00',
            data_type: 'number',
            description: "Sets the maximum number of direct reviews in relation to due direct review proportion to prevent a complete halt to work on other dockets should demand for direct reviews approach the Board's capacity.",
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'maximum_direct_review_proportion',
            lever_group: 'static',
            lever_group_order: 1000,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'Maximum Direct Review Proportion',
            unit: '%',
            updated_at: '2024-01-24T11:52:10.126-05:00',
            value: '0.8',
            backendValue: '0.8'
          },
          {
            id: 2,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.132-05:00',
            data_type: 'number',
            description: 'Sets the minimum proportion of legacy appeals that will be distributed.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'minimum_legacy_proportion',
            lever_group: 'static',
            lever_group_order: 1001,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'Minimum Legacy Proportion',
            unit: '%',
            updated_at: '2024-01-24T11:52:10.132-05:00',
            value: '0.2',
            backendValue: '0.2'
          },
          {
            id: 3,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.137-05:00',
            data_type: 'number',
            description: 'Applied for docket balancing reflecting the likelihood that NODs will advance to a Form 9.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'nod_adjustment',
            lever_group: 'static',
            lever_group_order: 1002,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'NOD Adjustment',
            unit: '%',
            updated_at: '2024-01-24T11:52:10.137-05:00',
            value: '0.9',
            backendValue: '0.9'
          },
          {
            id: 4,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.143-05:00',
            data_type: 'boolean',
            description: 'Distribute legacy cases tied to a judge to the Board-provided limit of 30, regardless of the legacy docket range.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'bust_backlog',
            lever_group: 'static',
            lever_group_order: 1003,
            max_value: null,
            min_value: null,
            options: null,
            title: 'Priority Bust Backlog',
            unit: '',
            updated_at: '2024-01-24T11:52:10.143-05:00',
            value: 'true',
            backendValue: 'true'
          }
        ],
        batch: [
          {
            id: 6,
            algorithms_used: [
              'docket',
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.152-05:00',
            data_type: 'number',
            description: 'Sets case-distribution batch size for judges with attorney teams. The value for this data element is per attorney.',
            is_disabled_in_ui: false,
            is_toggle_active: true,
            item: 'batch_size_per_attorney',
            lever_group: 'batch',
            lever_group_order: 2001,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'Batch Size Per Attorney*',
            unit: 'cases',
            updated_at: '2024-01-24T11:52:10.152-05:00',
            value: '3',
            backendValue: '3'
          },
          {
            id: 7,
            algorithms_used: [
              'docket',
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.157-05:00',
            data_type: 'number',
            description: 'Sets the number of remaining cases a VLJ must have equal to or less than to request more cases. (The number entered is used as equal to or less than)',
            is_disabled_in_ui: false,
            is_toggle_active: true,
            item: 'request_more_cases_minimum',
            lever_group: 'batch',
            lever_group_order: 2002,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'Request More Cases Minimum*',
            unit: 'cases',
            updated_at: '2024-01-31T19:33:20.727-05:00',
            value: '18',
            backendValue: '18'
          },
          {
            id: 5,
            algorithms_used: [
              'docket',
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.147-05:00',
            data_type: 'number',
            description: 'Sets case-distribution batch size for judges who do not have their own attorney teams.',
            is_disabled_in_ui: false,
            is_toggle_active: true,
            item: 'alternative_batch_size',
            lever_group: 'batch',
            lever_group_order: 2000,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'Alternate Batch Size*',
            unit: 'cases',
            updated_at: '2024-01-31T20:28:26.163-05:00',
            value: '12',
            backendValue: '12'
          }
        ],
        affinity: [
          {
            id: 8,
            algorithms_used: [
              'docket'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.162-05:00',
            data_type: 'radio',
            description: 'For non-priority AMA Hearing cases, sets the number of days an AMA Hearing Case is tied to the judge that held the hearing.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_hearing_case_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3000,
            max_value: 100,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 0,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days',
                min_value: 0,
                max_value: 100
              },
              {
                item: 'infinite',
                value: 'infinite',
                text: 'Always distribute to current judge'
              },
              {
                item: 'omit',
                value: 'omit',
                text: 'Omit variable from distribution rules'
              }
            ],
            title: 'AMA Hearing Case Affinity Days',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.162-05:00',
            value: 'value',
            currentValue: 0,
            backendValue: 0
          },
          {
            id: 9,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.167-05:00',
            data_type: 'radio',
            description: 'Sets the number of days an AMA Hearing appeal that is also AOD will respect the affinity to the most-recent hearing judge before distributing the appeal to any available judge.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_hearing_case_aod_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3001,
            max_value: 100,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 0,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days'
              },
              {
                item: 'infinite',
                data_type: '',
                value: 'infinite',
                text: 'Always distribute to current judge',
                unit: ''
              },
              {
                item: 'omit',
                data_type: '',
                value: 'omit',
                text: 'Omit variable from distribution rules',
                unit: ''
              }
            ],
            title: 'AMA Hearing Case AOD Affinity Days',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.167-05:00',
            value: 'value',
            currentValue: 0,
            backendValue: 0
          },
          {
            id: 10,
            algorithms_used: [
              'docket',
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.173-05:00',
            data_type: 'radio',
            description: 'Sets the number of days a case returned from CAVC respects the affinity to the judge who authored a decision before distributing the appeal to any available judge. This does not include Legacy CAVC Remand Appeals with a hearing held.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'cavc_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3002,
            max_value: 100,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 21,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days'
              },
              {
                item: 'infinite',
                value: 'infinite',
                text: 'Always distribute to current judge'
              },
              {
                item: 'omit',
                value: 'omit',
                text: 'Omit variable from distribution rules'
              }
            ],
            title: 'CAVC Affinity Days*',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.173-05:00',
            value: 'value',
            currentValue: 21,
            backendValue: 21
          },
          {
            id: 11,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.178-05:00',
            data_type: 'radio',
            description: 'Sets the number of days appeals returned from CAVC that are also AOD respect the affinity to the deciding judge. This is not applicable for legacy apeals for which the deciding judge conducted the most recent hearing.',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'cavc_aod_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3003,
            max_value: null,
            min_value: null,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 21,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days'
              },
              {
                item: 'infinite',
                value: 'infinite',
                text: 'Always distribute to current judge'
              },
              {
                item: 'omit',
                value: 'omit',
                text: 'Omit variable from distribution rules'
              }
            ],
            title: 'CAVC AOD Affinity Days',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.178-05:00',
            value: 'value',
            currentValue: 21,
            backendValue: 21
          },
          {
            id: 13,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.189-05:00',
            data_type: 'radio',
            description: 'Sets the number of days legacy remand Returned appeals that are also AOD (and may or may not have been CAVC at one time) respect the affinity before distributing the appeal to any available jduge. Affects appeals with hearing held when the remanding judge is not the hearing judge, or any legacy AOD + AOD appeal with no hearing held (whether or not it had been CAVC at one time).',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'aoj_aod_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3005,
            max_value: 100,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 14,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days'
              },
              {
                item: 'infinite',
                data_type: '',
                value: 'infinite',
                text: 'Always distribute to current judge',
                unit: ''
              },
              {
                item: 'omit',
                data_type: '',
                value: 'omit',
                text: 'Omit variable from distribution rules',
                unit: ''
              }
            ],
            title: 'AOJ AOD Affinity Days',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.189-05:00',
            value: 'value',
            currentValue: 14,
            backendValue: 14
          },
          {
            id: 14,
            algorithms_used: [
              'docket'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.195-05:00',
            data_type: 'radio',
            description: 'Sets the number of days AOJ appeals that were CAVC at some time respect the affinity before the appeal is distributed to any available judge. This applies to any AOJ + CAVC appeal with no hearing held, or those with a hearing held when the remanding judge is not the hearing judge.',
            is_disabled_in_ui: true,
            is_toggle_active: true,
            item: 'aoj_cavc_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3006,
            max_value: 100,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 21,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days'
              },
              {
                item: 'infinite',
                data_type: '',
                value: 'infinite',
                text: 'Always distribute to current judge',
                unit: ''
              },
              {
                item: 'omit',
                data_type: '',
                value: 'omit',
                text: 'Omit variable from distribution rules',
                unit: ''
              }
            ],
            title: 'AOJ CAVC Affinity Days',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.195-05:00',
            value: 'value',
            currentValue: 21,
            backendValue: 21
          },
          {
            id: 12,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.184-05:00',
            data_type: 'radio',
            description: 'Sets the number of days an appeal respects the affinity to the deciding judge for Legacy AOJ Remand Returned appeals with no hearing held before distributing the appeal to any available judge.',
            is_disabled_in_ui: false,
            is_toggle_active: false,
            item: 'aoj_affinity_days',
            lever_group: 'affinity',
            lever_group_order: 3004,
            max_value: 100,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'number',
                value: 60,
                text: 'Attempt distribution to current judge for max of:',
                unit: 'days'
              },
              {
                item: 'infinite',
                data_type: '',
                value: 'infinite',
                text: 'Always distribute to current judge',
                unit: ''
              },
              {
                item: 'omit',
                data_type: '',
                value: 'omit',
                text: 'Omit variable from distribution rules',
                unit: ''
              }
            ],
            title: 'AOJ Affinity Days',
            unit: 'days',
            updated_at: '2024-01-25T22:58:51.826-05:00',
            value: 'value',
            currentValue: 60,
            backendValue: 60
          }
        ],
        docket_distribution_prior: [
          {
            id: 15,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.200-05:00',
            data_type: 'combination',
            description: '',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_hearings_start_distribution_prior_to_goals',
            lever_group: 'docket_distribution_prior',
            lever_group_order: 4000,
            max_value: null,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'boolean',
                value: true,
                text: 'This feature is turned on or off',
                unit: ''
              }
            ],
            title: 'AMA Hearings Start Distribution Prior to Goals',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.200-05:00',
            value: '770',
            currentValue: 'false-770',
            backendValue: 'false-770'
          },
          {
            id: 16,
            algorithms_used: [
              'docket'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.205-05:00',
            data_type: 'combination',
            description: '',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_direct_review_start_distribution_prior_to_goals',
            lever_group: 'docket_distribution_prior',
            lever_group_order: 4001,
            max_value: null,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'boolean',
                value: true,
                text: 'This feature is turned on or off',
                unit: ''
              }
            ],
            title: 'AMA Direct Review Start Distribution Prior to Goals',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.205-05:00',
            value: '365',
            currentValue: 'false-365',
            backendValue: 'false-365'
          },
          {
            id: 17,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.211-05:00',
            data_type: 'combination',
            description: '',
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_evidence_submission_start_distribution_prior_to_goals',
            lever_group: 'docket_distribution_prior',
            lever_group_order: 4002,
            max_value: null,
            min_value: 0,
            options: [
              {
                item: 'value',
                data_type: 'boolean',
                value: true,
                text: 'This feature is turned on or off',
                unit: ''
              }
            ],
            title: 'AMA Evidence Submission Start Distribution Prior to Goals',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.211-05:00',
            value: '550',
            currentValue: 'false-550',
            backendValue: 'false-550'
          }
        ],
        docket_time_goal: [
          {
            id: 18,
            algorithms_used: [
              'docket'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.216-05:00',
            data_type: 'number',
            description: null,
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_hearings_docket_time_goals',
            lever_group: 'docket_time_goal',
            lever_group_order: 4003,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'AMA Hearings Docket Time Goals',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.216-05:00',
            value: '365',
            backendValue: '365'
          },
          {
            id: 20,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.228-05:00',
            data_type: 'number',
            description: null,
            is_disabled_in_ui: true,
            is_toggle_active: false,
            item: 'ama_evidence_submission_docket_time_goals',
            lever_group: 'docket_time_goal',
            lever_group_order: 4005,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'AMA Evidence Submission Docket Time Goals',
            unit: 'days',
            updated_at: '2024-01-24T11:52:10.228-05:00',
            value: '123',
            backendValue: '123'
          },
          {
            id: 19,
            algorithms_used: [
              'proportion'
            ],
            control_group: null,
            created_at: '2024-01-24T11:52:10.222-05:00',
            data_type: 'number',
            description: null,
            is_disabled_in_ui: false,
            is_toggle_active: true,
            item: 'ama_direct_review_docket_time_goals',
            lever_group: 'docket_time_goal',
            lever_group_order: 4004,
            max_value: null,
            min_value: 0,
            options: null,
            title: 'AMA Direct Review Docket Time Goals',
            unit: 'days',
            updated_at: '2024-01-25T23:30:33.484-05:00',
            value: '50',
            backendValue: '50'
          }
        ]
      }
    };

    const newState = leversReducer(initialState, action);

    expect(newState).toEqual(expectedState);
  });
});
