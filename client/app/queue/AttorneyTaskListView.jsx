import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import { attorneyLegacyAssignedTasksSelector } from './selectors';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import COPY from '../../COPY';

const containerStyles = css({
  position: 'relative'
});

class AttorneyTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();

    if (_.some(this.props.workableTasks, (task) => !task.taskId)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  render = () => {
    const { error, success } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {error && <Alert type="error" title={error.title}>
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title}>
        {success.detail || (success.title.includes('You have successfully reassigned ') && COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL)}
      </Alert>}
      <QueueTableBuilder
        assignedTasks={this.props.workableTasks}
        requireDasRecord
      />
    </AppSegment>;
  }
}

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
    workableTasks: attorneyLegacyAssignedTasksSelector(state),
    success: messages.success,
    error: messages.error,
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

export default (connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskListView));

AttorneyTaskListView.propTypes = {
  workableTasks: PropTypes.array,
  clearCaseSelectSearch: PropTypes.func,
  hideSuccessMessage: PropTypes.func,
  resetSaveState: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  showErrorMessage: PropTypes.func,
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  })
};
