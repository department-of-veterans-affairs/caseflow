import React from 'react';
import { render, screen } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import PactBadge from './PactBadge';

describe('PactBadge', () => {
  const defaultAppeal = {
    pact: true,
  };
  const tooltipText = 'Appeal has issue(s) related to Promise to Address Comprehensive Toxics (PACT) Act.';

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupPactBadge = (store) => {
    return render(
      <Provider store={store}>
        <PactBadge
          appeal={defaultAppeal}
          tooltipText={tooltipText}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const {asFragment} = setupPactBadge(store);

    expect(screen.getByText('PACT')).toBeInTheDocument();
    expect(screen.getByText(tooltipText)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
