import React from 'react';
import { render, screen } from '@testing-library/react';
import LeverHistory from 'app/caseDistribution/components/LeverHistory';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { loadLevers } from '../../../../../client/app/caseDistribution/reducers/levers/leversActions';
import ACD_LEVERS from '../../../../constants/ACD_LEVERS';
import DISTRIBUTION from '../../../../constants/DISTRIBUTION';

jest.mock('app/styles/caseDistribution/LeverHistory.module.scss', () => '');

describe('LeverHistory', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('renders the "LeverHistory Component" with the proper history data imported', () => {

    let testHistory = [
      {
        case_distribution_lever_id: 5,
        created_at: '2024-01-12T16:48:35.422-05:00',
        id: 27,
        lever_data_type: 'number',
        lever_title: 'Alternate Batch Size*',
        lever_unit: 'cases',
        previous_value: '15',
        update_value: '70',
        user_name: 'Deborah BvaIntakeAdmin Wise'
      }
    ];

    let levers = {
      batch: [
        {
          item: DISTRIBUTION.alternative_batch_size,
          title: 'Alternate Batch Size*',
          description: 'Sets case-distribution batch size for judges who do not have their own attorney teams.',
          data_type: ACD_LEVERS.data_types.number,
          value: 15,
          unit: ACD_LEVERS.cases,
          is_toggle_active: true,
          is_disabled_in_ui: false,
          min_value: 0,
          max_value: 100,
          algorithms_used: [ACD_LEVERS.algorithms.docket, ACD_LEVERS.algorithms.proportion],
          lever_group: ACD_LEVERS.lever_groups.batch,
          lever_group_order: 2000
        },
      ] };

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    store.dispatch(loadLevers(levers, testHistory));

    render(
      <Provider store={store}>
        <LeverHistory />
      </Provider>
    );

    expect(screen.getByText('Fri, Jan 12, 2024 16:48:35')).toBeInTheDocument();
    expect(screen.getByText('Deborah BvaIntakeAdmin Wise')).toBeInTheDocument();
    expect(screen.getByText('Alternate Batch Size*')).toBeInTheDocument();
    expect(screen.getByText('15 cases')).toBeInTheDocument();
    expect(screen.getByText('70 cases')).toBeInTheDocument();
  });

});
