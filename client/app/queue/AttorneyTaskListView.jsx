import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { css } from 'glamor';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Alert from '../components/Alert';

import {
  completeTasksByAssigneeCssIdSelector,
  workableTasksByAssigneeCssIdSelector,
  onHoldTasksForAttorney
} from './selectors';

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

    if (_.some(
      [...this.props.workableTasks, ...this.props.onHoldTasks, ...this.props.completedTasks],
      (task) => !task.taskId)) {
      this.props.showErrorMessage({
        title: COPY.TASKS_NEED_ASSIGNMENT_ERROR_TITLE,
        detail: COPY.TASKS_NEED_ASSIGNMENT_ERROR_MESSAGE
      });
    }
  };

  render = () => {
    const { error, success } = this.props;
    const noOpenTasks = !_.size([...this.props.workableTasks, ...this.props.onHoldTasks]);
    const noCasesMessage = noOpenTasks ?
      <p>
        {COPY.NO_CASES_IN_QUEUE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> : '';

    return <AppSegment filledBackground styling={containerStyles}>
      {error && <Alert type="error" title={error.title}>
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title}>
        {success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      {noCasesMessage}
      <QueueTableBuilder
        assignedTasks={this.props.workableTasks}
        onHoldTasks={this.props.onHoldTasks}
        completedTasks={this.props.completedTasks}
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
    workableTasks: workableTasksByAssigneeCssIdSelector(state),
    onHoldTasks: onHoldTasksForAttorney(state),
    completedTasks: completeTasksByAssigneeCssIdSelector(state),
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
  completedTasks: PropTypes.array,
  hideSuccessMessage: PropTypes.func,
  resetSaveState: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  showErrorMessage: PropTypes.func,
  onHoldTasks: PropTypes.array,
  paginationOptions: PropTypes.object,
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  })
};
