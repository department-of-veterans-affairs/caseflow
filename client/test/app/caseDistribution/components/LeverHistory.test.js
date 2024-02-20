import React from 'react';
import { render, screen } from '@testing-library/react';
import LeverHistory from 'app/caseDistribution/components/LeverHistory';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';
import rootReducer from 'app/caseDistribution/reducers/root';
import thunk from 'redux-thunk';
import { loadHistory } from '../../../../../client/app/caseDistribution/reducers/levers/leversActions';

describe('LeverHistory', () => {

  afterEach(() => {
    jest.clearAllMocks();
  });

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
      user_css_id: 'BVADWISE'
    }
  ];

  let testHistory2 = [
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
    },
    {
      case_distribution_lever_id: 5,
      created_at: '2023-01-11T15:48:35.422-05:00',
      id: 26,
      lever_data_type: 'number',
      lever_title: 'Batch Size Per Attorney*',
      lever_unit: 'cases',
      previous_value: '30',
      update_value: '37',
      user_css_id: 'BVADWISE'
    }
  ];

  it('renders the "LeverHistory Component" with the proper history data imported', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    store.dispatch(loadHistory(testHistory));

    render(
      <Provider store={store}>
        <LeverHistory />
      </Provider>
    );

    expect(screen.getByText('Fri, Jan 12, 2024 16:48:35')).toBeInTheDocument();
    expect(screen.queryByText('Thu, Jan 11, 2023 15:48:35')).not.toBeInTheDocument();
    expect(screen.getByText('BVADWISE')).toBeInTheDocument();
    expect(screen.getByText('Alternate Batch Size*')).toBeInTheDocument();
    expect(screen.queryByText('Batch Size Per Attorney*')).not.toBeInTheDocument();
    expect(screen.getByText('15 cases')).toBeInTheDocument();
    expect(screen.getByText('70 cases')).toBeInTheDocument();
    expect(screen.queryByText('30 cases')).not.toBeInTheDocument();
    expect(screen.queryByText('37 cases')).not.toBeInTheDocument();
  });

  it('renders the "LeverHistory Component" with multiple history entries', () => {

    const getStore = () => createStore(
      rootReducer,
      applyMiddleware(thunk));

    const store = getStore();

    store.dispatch(loadHistory(testHistory2));

    render(
      <Provider store={store}>
        <LeverHistory />
      </Provider>
    );

    expect(screen.getByText('Fri, Jan 12, 2024 16:48:35')).toBeInTheDocument();
    expect(screen.getByText('Wed, Jan 11, 2023 15:48:35')).toBeInTheDocument();
    expect(screen.getByText('Alternate Batch Size*')).toBeInTheDocument();
    expect(screen.getByText('Batch Size Per Attorney*')).toBeInTheDocument();
    expect(screen.getByText('15 cases')).toBeInTheDocument();
    expect(screen.getByText('70 cases')).toBeInTheDocument();
    expect(screen.getByText('30 cases')).toBeInTheDocument();
    expect(screen.getByText('37 cases')).toBeInTheDocument();
  });

});
