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
import COPY from '../../../COPY.json';

class JudgeReviewTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  render = () => {
    const reviewableCount = _.filter(
      this.props.tasks,
      (task) => task.attributes.task_type === 'Review').length;
    let tableContent;

    if (reviewableCount === 0) {
      tableContent = <StatusMessage title={COPY.NO_CASES_FOR_JUDGE_REVIEW_TITLE}>
        {COPY.NO_CASES_FOR_JUDGE_REVIEW_MESSAGE}
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 {...fullWidth}>{sprintf(COPY.JUDGE_CASE_REVIEW_TABLE_TITLE, reviewableCount)}</h1>
        <JudgeReviewTaskTable />
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
