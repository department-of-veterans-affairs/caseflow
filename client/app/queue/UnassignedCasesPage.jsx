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
import { judgeAssignTasksSelector, selectedTasksSelector } from './selectors';
import type { LegacyTask, AmaTask } from './types/models';
import Alert from '../components/Alert';
import type { UiStateMessage } from './types/state';

type Params = {|
  userId: string,
|};

type Props = Params & {|
  // Props
  featureToggles: Object,
  selectedTasks: Array<LegacyTask>,
  error: ?UiStateMessage,
  success: ?UiStateMessage,
  tasks: Array<LegacyTask | AmaTask>,
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
    const { userId, featureToggles, selectedTasks, success, error } = this.props;

    return <React.Fragment>
      <h2>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
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
        includeDaysWaiting
        includeReaderLink
        tasks={this.props.tasks}
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
      featureToggles,
      messages: {
        success,
        error
      }
    }
  } = state;

  return {
    tasks: judgeAssignTasksSelector(state),
    isTaskAssignedToUserSelected,
    featureToggles,
    selectedTasks: selectedTasksSelector(state, ownProps.userId),
    success,
    error
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage): React.ComponentType<Params>);
