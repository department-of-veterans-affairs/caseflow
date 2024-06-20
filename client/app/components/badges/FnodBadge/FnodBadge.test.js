import React from 'react';
import { render, screen } from '@testing-library/react';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import FnodBadge from './FnodBadge';

describe('FnodBadge', () => {
  const defaultAppeal = {
    veteranAppellantDeceased: true,
    veteranDateOfDeath: '2019-03-17'
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupFnodBadge = (store) => {
    return (
      <Provider store={store}>
        <FnodBadge
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = render(setupFnodBadge(store));
    console.log(asFragment());
    expect(asFragment()).toMatchSnapshot();
  });
});
