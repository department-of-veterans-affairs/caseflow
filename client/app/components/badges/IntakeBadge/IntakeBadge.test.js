import React from 'react';
import { render } from '@testing-library/react';
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
    return (
      <Provider store={store}>
        <IntakeBadge
          review={defaultReview}
        />
      </Provider>
    );
  };

  it('renders correctly', () => {
    const store = getStore();
    const { asFragment } = render(setupIntakeBadge(store));

    expect(asFragment()).toMatchSnapshot();
  });
});
