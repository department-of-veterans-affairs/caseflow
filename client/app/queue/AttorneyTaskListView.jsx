import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import TaskTable from './components/TaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  tasksByAssigneeCssIdSelector
} from './selectors';
import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import COPY from '../../COPY.json';

class AttorneyTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();

    if (_.some(this.props.tasks, (task) => !task.taskId)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  render = () => {
    const { messages } = this.props;
    const noTasks = !_.size(this.props.tasks);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title={COPY.NO_TASKS_IN_ATTORNEY_QUEUE_TITLE}>
        {COPY.NO_TASKS_IN_ATTORNEY_QUEUE_MESSAGE}
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 {...fullWidth}>{COPY.ATTORNEY_QUEUE_TABLE_TITLE}</h1>
        {messages.error && <Alert type="error" title={messages.error.title}>
          {messages.error.detail}
        </Alert>}
        {messages.success && <Alert type="success" title={messages.success.title}>
          {messages.success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
        </Alert>}
        <TaskTable
          includeDetailsLink
          includeType
          includeDocketNumber
          includeIssueCount
          includeDueDate
          includeReaderLink
          requireDasRecord
          tasks={this.props.tasks}
        />
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

AttorneyTaskListView.propTypes = {
  tasks: PropTypes.object.isRequired
};

const mapStateToProps = (state) => {
  const {
    queue: {
      stagedChanges: {
        taskDecision
      }
    },
    ui: {
      messages
    }
  } = state;

  return ({
    tasks: tasksByAssigneeCssIdSelector(state),
    messages,
    taskDecision
  });
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    showErrorMessage
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskListView);
