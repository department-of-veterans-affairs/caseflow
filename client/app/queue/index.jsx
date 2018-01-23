import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/ReduxBase';
import queueReducer, { initialState } from './reducers';

import QueueApp from './QueueApp';

const Queue = (props) => <ReduxBase reducer={queueReducer} store={initialState}>
  <QueueApp {...props} />
</ReduxBase>;

export default Queue;
