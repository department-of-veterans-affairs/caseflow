import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import JudgeReviewTaskTable from './JudgeReviewTaskTable';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';

const DISPLAYING_REVIEW_TASKS = {
  title: (reviewableCount) => <h1 {...fullWidth}>Review {reviewableCount} Cases</h1>,
  switchLink: (that) => <a onClick={() => that.handleSwitchToAssign()} href="#">Switch to Assign Cases</a>,
  visibleTasks: (tasks) => _.filter(tasks, (task) => task.attributes.task_type === 'Review'),
  noTasksMessage: () => 'Congratulations! You don\'t have any decisions to sign.',
  table: () => <JudgeReviewTaskTable />
};

const DISPLAYING_ASSIGN_TASKS = {
  title: (reviewableCount) => <h1 {...fullWidth}>Assign {reviewableCount} Cases</h1>,
  switchLink: (that) => <a onClick={() => that.handleSwitchToReview()} href="#">Switch to Review Cases</a>,
  visibleTasks: (tasks) => _.filter(tasks, (task) => task.attributes.task_type === 'Assign'),
  noTasksMessage: () => 'Congratulations! You don\'t have any cases to assign.',
  table: () => <JudgeAssignTaskTable />
};

class JudgeTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  constructor(props) {
    super(props);
    this.state = DISPLAYING_REVIEW_TASKS;
  }

  handleSwitchToAssign = () => this.setState(DISPLAYING_ASSIGN_TASKS)

  handleSwitchToReview = () => this.setState(DISPLAYING_REVIEW_TASKS)

  render = () => {
    const reviewableCount = this.state.visibleTasks(this.props.tasks).length;
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <div>
        {this.state.title(reviewableCount)}
        {this.state.switchLink(this)}
        <StatusMessage title="Tasks not found">
          {this.state.noTasksMessage()}
        </StatusMessage>
      </div>;
    } else {
      tableContent = <div>
        {this.state.title(reviewableCount)}
        {this.state.switchLink(this)}
        {this.state.table()}
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

JudgeTaskListView.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => (
  _.pick(state.queue.loadedQueue, 'tasks', 'appeals'));

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeTaskListView);
