// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import TaskTable from './components/TaskTable';
import {
  initialAssignTasksToUser
} from './QueueActions';
import AssignWidget from './components/AssignWidget';
import { JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE } from '../../COPY.json';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import { unassignedAppealsSelector, selectedTasksSelector } from './selectors';
import type { Task, LegacyAppeals } from './types/models';

type Params = {|
  userId: string,
|};

type Props = Params & {|
  // Props
  featureToggles: Object,
  selectedTasks: Array<Task>,
  appeals: LegacyAppeals,
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
    const { userId, featureToggles, selectedTasks } = this.props;

    return <React.Fragment>
      <h2>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {featureToggles.judge_assignment_to_attorney &&
        <AssignWidget
          previousAssigneeId={userId}
          onTaskAssignment={(params) => this.props.initialAssignTasksToUser(params)}
          selectedTasks={selectedTasks} />}
      <TaskTable
        includeSelect
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDocumentCount
        includeDaysWaiting
        appeals={this.props.appeals}
        userId={userId} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const {
    queue: {
      isTaskAssignedToUserSelected
    },
    ui: {
      featureToggles
    }
  } = state;

  return {
    appeals: unassignedAppealsSelector(state),
    isTaskAssignedToUserSelected,
    featureToggles,
    selectedTasks: selectedTasksSelector(state, ownProps.userId)
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage): React.ComponentType<Params>);
