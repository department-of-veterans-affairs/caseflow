import React from 'react';
import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import { MemoryRouter as Router } from 'react-router-dom';
import { Provider } from 'react-redux';
import { applyMiddleware, createStore } from 'redux';
import thunk from 'redux-thunk';
import rootReducer from 'app/queue/reducers';

import FunctionConfiguration from '../../../app/test/loadTest/FunctionConfiguration';

describe('FunctionConfiguration', () => {
  const defaultProps = {
    functionOption: 'Function1',
    currentState: {
      scenarios: [],
      user: {
        station_id: '',
        regional_office: '',
        roles: [],
        functions: {},
        organizations: [],
        feature_toggles: {}
      }
    },
    updateState: jest.fn()
  };

  const store = createStore(rootReducer, applyMiddleware(thunk));

  const setup = (props) =>
    render(
      <Provider store={store}>
        <Router>
          <FunctionConfiguration {...props} />
        </Router>
      </Provider>
    );

  it('renders the Function component', async () => {
    expect(setup(defaultProps)).toMatchSnapshot();
    expect(await screen.findByLabelText('Function1')).toBeInTheDocument();
  });
});
