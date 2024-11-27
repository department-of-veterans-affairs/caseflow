import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

import LoadTest from '../../../app/test/loadTest/LoadTest';

describe('LoadTest', () => {
  const defaultProps = {
    form_values: {
      all_csum_roles: ['Admin Intake', 'Build HearSched'],
      all_organizations: ['AOD', 'Alexandra Jackson', 'BVA Intake'],
      feature_toggles_available: [
        {
          name: 'acd_cases_tied_to_judges_no_longer_with_board',
          default_status: true
        },
        {
          name: 'acd_disable_legacy_lock_ready_appeals',
          default_status: false
        }
      ],
      functions_available: ['System Admin']
    }
  };

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <Router>
          <LoadTest {...props} />
        </Router>
      </Provider>
    );

  it('renders the Test Target Configuration page', async () => {

    expect(setup(defaultProps)).toMatchSnapshot();
    expect(await screen.findByText('Welcome to the Caseflow Load Test page')).toBeInTheDocument();
  });
});
