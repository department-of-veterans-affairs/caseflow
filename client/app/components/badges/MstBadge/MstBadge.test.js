import React from 'react';
import { render } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import MstBadge from './MstBadge';

describe('MstBadge', () => {
  const defaultAppeal = {
    mst: true,
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupMstBadge = (store) => {
    return (
      <Provider store={store}>
        <MstBadge
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = render(setupMstBadge(store));
    expect(asFragment()).toMatchSnapshot();
  });
});
