import React from 'react';
import { mount } from 'enzyme';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import PactBadge from './PactBadge';

describe('PactBadge', () => {
  const defaultAppeal = {
    pact: true,
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupPactBadge = (store) => {
    return mount(
      <Provider store={store}>
        <PactBadge
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const component = setupPactBadge(store);

    expect(component).toMatchSnapshot();
  });
});
