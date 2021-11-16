import React from 'react';
import { mount } from 'enzyme';
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
    return mount(
      <Provider store={store}>
        <ContestedClaimBadge
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const component = setupContestedClaimBadge(store);

    expect(component).toMatchSnapshot();
  });
});
