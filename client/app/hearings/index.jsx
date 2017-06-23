import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import configureStore from '../util/ConfigureStore';

import Dockets from './Dockets';
import { hearingsReducers, mapDataToInitialState } from './reducers/index';

const Hearings = ({ hearings }) => {
  const initialState = mapDataToInitialState(hearings);
  const store = configureStore({
    reducers: hearingsReducers,
    initialState
  });

  if (module.hot) {
    // Enable Webpack hot module replacement for reducers.
    // Changes made to the reducers while developing should be
    // available instantly.
    // Note that this expects the global reducer
    // to be present at reducers/index.
    module.hot.accept('./reducers/index', () => {
      store.replaceReducer(hearingsReducers);
    });
  }

  return <Provider store={store}>
    <div>
      <BrowserRouter>
        <div>
        <Route path="/hearings/dockets"
          component={() => (<Dockets veteran_law_judge={hearings.veteran_law_judge} />)}/>
      </div>
      </BrowserRouter>
    </div>
  </Provider>;
};

export default Hearings;
