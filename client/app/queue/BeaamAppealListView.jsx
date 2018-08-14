import React from 'react';
import { connect } from 'react-redux';

import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';
import _ from 'lodash';
import {
  tasksWithAppealSelector
} from './selectors';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class BeaamListView extends React.PureComponent {
  render = () => {
    const { messages } = this.props;

    return <AppSegment filledBackground>
      <div>
        <h1 {...fullWidth}>{COPY.BEAAM_QUEUE_TABLE_TITLE}</h1>
        {messages.error && <Alert type="error" title={messages.error.title}>
          {messages.error.detail}
        </Alert>}
        <TaskTable
          includeDetailsLink
          includeType
          includeDocketNumber
          includeIssueCount
          includeReaderLink
          tasks={this.props.tasks} />
      </div>
    </AppSegment>;
  };
}

const mapStateToProps = (state) => ({
  ..._.pick(state.ui, 'messages'),
  tasks: tasksWithAppealSelector(state)
});

export default connect(mapStateToProps)(BeaamListView);
