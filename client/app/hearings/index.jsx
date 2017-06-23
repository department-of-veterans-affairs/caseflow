import React from 'react';
import { BrowserRouter, Route } from 'react-router-dom';
import { Provider } from 'react-redux';
import configureStore from '../util/ConfigureStore';

import ConfigUtil from '../util/ConfigUtil';
import Dockets from './Dockets';
import { hearingsReducers, mapDataToInitialState } from './reducers/index';

const Hearings = ({ hearings }) => {
  const initialState = mapDataToInitialState(data);
  const reducers = hearingsReducers;
  const store = configureStore({
    reducers,
    initialState
  });

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
