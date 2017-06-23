import React from 'react';
import { Provider } from 'react-redux';
import DecisionReviewer from './DecisionReviewer';
import readerReducer from './reducer';
import configureStore from '../util/ConfigureStore';

const store = configureStore({ reducers: readerReducer });

if (module.hot) {
  // Enable Webpack hot module replacement for reducers.
  // Changes made to the reducers while developing should be
  // available instantly.
  // Note that this expects the global reducer for each app
  // to be present at reducers/index.
  module.hot.accept('./reducer', () => {
    store.replaceReducer(readerReducer);
  });
}

const Reader = (props) => {
  return <Provider store={store}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
