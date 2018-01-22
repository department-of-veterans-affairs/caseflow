import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/ReduxBase';
import queueReducer, { initialState } from './reducers';

import QueueManager from './QueueManager';

const QueueBase = (props) => <ReduxBase reducer={queueReducer} store={initialState}>
  <QueueManager {...props} />
</ReduxBase>;

export default QueueBase;
