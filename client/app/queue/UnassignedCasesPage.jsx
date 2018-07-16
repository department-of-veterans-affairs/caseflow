// @flow
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import JudgeAssignTaskTable from './JudgeAssignTaskTable';
import {
  initialAssignTasksToUser
} from './QueueActions';
import AssignWidget from './components/AssignWidget';
import { JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE } from '../../COPY.json';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import _ from 'lodash';
import type { Tasks, IsTaskAssignedToUserSelected } from './types';

type Props = {|
  // Parameters
  userId: string,
  // Props
  tasks: Tasks,
  isTaskAssignedToUserSelected: IsTaskAssignedToUserSelected,
  featureToggles: Object,
  // Action creators
  initialAssignTasksToUser: typeof initialAssignTasksToUser,
  resetErrorMessages: typeof resetErrorMessages,
  resetSuccessMessages: typeof resetSuccessMessages
|};

class UnassignedCasesPage extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  render = () => {
    const { userId, featureToggles } = this.props;

    return <React.Fragment>
      <h2>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {featureToggles.judge_assign_cases &&
        <AssignWidget
          previousAssigneeId={userId}
          onTaskAssignment={(params) => this.props.initialAssignTasksToUser(params)} />}
      <JudgeAssignTaskTable {...this.props} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => {
  const {
    queue: {
      tasks,
      isTaskAssignedToUserSelected
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    tasks,
    isTaskAssignedToUserSelected,
    featureToggles
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage);
