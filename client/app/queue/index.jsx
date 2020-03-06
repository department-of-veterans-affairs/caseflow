import React from 'react';
import queueReducer, { initialState } from './reducers';

import QueueApp from './QueueApp';
import ReduxBase from '../components/ReduxBase';

const Queue = (props) => {
  return (
    <ReduxBase reducer={queueReducer} initialState={{ queue: { ...initialState } }}>
      <QueueApp {...props} />
    </ReduxBase>
  );
};

export default Queue;
