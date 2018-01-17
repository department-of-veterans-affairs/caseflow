import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/ReduxBase';

import QueueManager from './QueueManager';

import rootReducer from './reducers';

export default class WorkQueue extends React.Component {
  render = () => <ReduxBase reducer={rootReducer}>
    <QueueManager {...this.props} />
  </ReduxBase>;
}
