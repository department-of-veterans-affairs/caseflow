import React from 'react';
import { mount } from 'enzyme';
import thunk from 'redux-thunk';
import { Provider } from 'react-redux';
import { createStore, applyMiddleware } from 'redux';

import rootReducer from 'app/queue/reducers';
import IntakeBadge from './IntakeBadge';

describe('IntakeBadge', () => {
  const defaultReview = {
    intakeFromVbms: true,
  };

  const getStore = () => createStore(rootReducer, applyMiddleware(thunk));

  const setupIntakeBadge = (store) => {
    return mount(
      <Provider store={store}>
        <IntakeBadge
          review={defaultReview}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const component = setupIntakeBadge(store);

    expect(component).toMatchSnapshot();
  });
});
