import React from 'react';
import { render, screen } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import MstBadge from './MstBadge';

describe('MstBadge', () => {
  const defaultAppeal = {
    id: '1234',
    mst: true,
  };
  const tooltipText = 'Appeal has issue(s) related to Military Sexual Trauma';

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupMstBadge = (store) => {
    return (
      <Provider store={store}>
        <MstBadge
          appeal={defaultAppeal}
          tooltipText={tooltipText}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = render(setupMstBadge(store));

    expect(screen.getByText('MST')).toBeInTheDocument();
    expect(screen.getByText(tooltipText)).toBeInTheDocument();
    expect(asFragment()).toMatchSnapshot();
  });
});
