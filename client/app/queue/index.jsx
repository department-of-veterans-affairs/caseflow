import React from 'react';
import { Router } from 'react-router';
import queueReducer, { initialState } from './reducers';

import QueueApp from './QueueApp';
import ReduxBase from '../components/ReduxBase';
import { createBrowserHistory } from 'history';

const history = createBrowserHistory();

const Queue = (props) => {
  return (
    <ReduxBase
      reducer={queueReducer}
      initialState={{ queue: { ...initialState } }}
      thunkArgs={{ history }}
    >
      <Router history={history}>
        <QueueApp {...props} />
      </Router>
    </ReduxBase>
  );
};

export default Queue;
