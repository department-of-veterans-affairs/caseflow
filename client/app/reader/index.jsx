import React from 'react';
import { Provider } from 'react-redux';
import DecisionReviewer from './DecisionReviewer';
import readerReducer from './reducers/index';
import configureStore from '../util/ConfigureStore';

const Reader = (props) => {
  const reducers = readerReducer;
  const store = configureStore({
    reducers
  });

  return <Provider store={store}>
      <DecisionReviewer {...props} />
  </Provider>;
};

export default Reader;
