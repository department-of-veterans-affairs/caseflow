import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { sprintf } from 'sprintf-js';

import StatusMessage from '../components/StatusMessage';
import JudgeReviewTaskTable from './JudgeReviewTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import COPY from '../../../COPY.json';

const DISPLAYING_REVIEW_TASKS = {
  title: (reviewableCount) => <h1 {...fullWidth}>{sprintf(COPY.JUDGE_CASE_REVIEW_TABLE_TITLE, reviewableCount)}</h1>,
  switchLink: (that) => <Link to={`/queue/${that.props.userId}/assign`}>{COPY.SWITCH_TO_ASSIGN_MODE_LINK_LABEL}</Link>,
  visibleTasks: (tasks) => _.filter(tasks, (task) => task.attributes.task_type === 'Review'),
  noTasksMessage: () => COPY.NO_CASES_FOR_JUDGE_REVIEW_MESSAGE,
  table: () => <JudgeReviewTaskTable />
};

class JudgeReviewTaskListView extends React.PureComponent {
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

  render = () => {
    const reviewableCount = this.state.visibleTasks(this.props.tasks).length;
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <div>
        {this.state.title(reviewableCount)}
        {this.state.switchLink(this)}
        <StatusMessage title={COPY.NO_CASES_FOR_JUDGE_REVIEW_TITLE}>
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

JudgeReviewTaskListView.propTypes = {
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

export default connect(mapStateToProps, mapDispatchToProps)(JudgeReviewTaskListView);
