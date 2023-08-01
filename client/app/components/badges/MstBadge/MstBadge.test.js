import React from 'react';
import { mount } from 'enzyme';
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
    return mount(
      <Provider store={store}>
        <MstBadge
          appeal={defaultAppeal}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const component = setupMstBadge(store);

    expect(component).toMatchSnapshot();
  });
});
