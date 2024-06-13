import React from 'react';
import { render, screen } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import ContestedClaimBadge from './ContestedClaimBadge';

describe('ContestedClaimBadge', () => {
  const defaultAppeal = {
    contested_claim: true,
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupContestedClaimBadge = (store) => {
    return (
      <Provider store={store}>
        <ContestedClaimBadge
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = render(setupContestedClaimBadge(store));
    expect(asFragment()).toMatchSnapshot();
  });
});
