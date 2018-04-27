import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

const DISPLAYING_ASSIGN_TASKS = {
  title: (reviewableCount) => <h1 {...fullWidth}>Assign {reviewableCount} Cases</h1>,
  switchLink: (that) => <Link to={`/${that.props.userId}/review`}>Switch to Review Cases</Link>,
  visibleTasks: (tasks) => _.filter(tasks, (task) => task.attributes.task_type === 'Assign'),
  noTasksMessage: () => 'Congratulations! You don\'t have any cases to assign.',
  table: () => <JudgeAssignTaskTable />
};

class JudgeAssignTaskListView extends React.PureComponent {
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
    this.state = DISPLAYING_ASSIGN_TASKS;
  }

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

JudgeAssignTaskListView.propTypes = {
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

export default connect(mapStateToProps, mapDispatchToProps)(JudgeAssignTaskListView);
