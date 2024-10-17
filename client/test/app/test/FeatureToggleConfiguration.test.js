import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore, compose } from 'redux';
import thunk from 'redux-thunk';

import FeatureToggleConfiguration from '../../../app/test/loadTest/FeatureToggleConfiguration';

const createStoreWithReducer = (initialState) => {
  const reducer = (state = initialState) => state;

  return createStore(reducer, compose(applyMiddleware(thunk)));
};

const renderFeatureToggleConfiguration = (props) => {
  const store = createStoreWithReducer({ components: {} });

  return render(
    <Provider store={store}>
      <Router>
        <FeatureToggleConfiguration {...props} />
      </Router>
    </Provider>
  );
};

describe('FeatureToggleConfiguration', () => {
  it('renders the FeatureToggleConfiguration component', async () => {
    const mockProps = {
      featureToggle: 'Feature1',
      currentState: {
        scenarios: [],
        user: {
          user: {
            station_id: '',
            regional_office: '',
            roles: [],
            functions: {},
            organizations: [],
            feature_toggles: {}
          }
        }
      },
      updateState: jest.fn()
    };

    renderFeatureToggleConfiguration(mockProps);
    expect(await screen.findByText(/Feature1/)).toBeInTheDocument();
  });
});
