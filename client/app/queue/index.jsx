import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/ReduxBase';

import QueueManager from './QueueManager';

import rootReducer from './reducers';

export default function WorkQueue(props) {
  return <ReduxBase reducer={rootReducer}>
    <QueueManager {...props} />
  </ReduxBase>;
}
