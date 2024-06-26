import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import ContestedClaimBadge from './ContestedClaimBadge';
import COPY from 'COPY';

describe('ContestedClaimBadge', () => {
  const defaultAppeal = {
    id: '1234',
    contestedClaim: true
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

  it('renders correctly', async () => {
    const store = getStore();
    const { asFragment } = render(setupContestedClaimBadge(store));

    waitFor(() => {
      expect(screen.getByText('CC')).toBeInTheDocument();
      expect(screen.getByText(COPY.CC_BADGE_TOOLTIP)).toBeInTheDocument();
    });

    expect(asFragment()).toMatchSnapshot();
  });
});
