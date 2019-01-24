// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import StatusMessage from '../components/StatusMessage';
import TaskTable from './components/TaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { reassignTasksToUser } from './QueueActions';
import { selectedTasksSelector, getAssignedTasks } from './selectors';
import AssignWidget from './components/AssignWidget';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import Alert from '../components/Alert';
import type { Task, TaskWithAppeal, Appeals } from './types/models';
import type { AttorneysOfJudge, AttorneyAppealsLoadingState, UiStateMessage, State } from './types/state';

type Params = {|
  match: Object
|};

type Props = Params & {|
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  appealsOfAttorney: Appeals,
  selectedTasks: Array<Task>,
  tasksOfAttorney: Array<TaskWithAppeal>,
  attorneyAppealsLoadingState: AttorneyAppealsLoadingState,
  success: ?UiStateMessage,
  error: ?UiStateMessage,
  // Action creators
  resetSuccessMessages: typeof resetSuccessMessages,
  resetErrorMessages: typeof resetErrorMessages,
  reassignTasksToUser: typeof reassignTasksToUser
|};

class AssignedCasesPage extends React.Component<Props> {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidUpdate = (prevProps) => {
    const { attorneyId: prevAttorneyId } = prevProps.match.params;
    const { attorneyId } = this.props.match.params;

    if (attorneyId !== prevAttorneyId) {
      this.props.resetSuccessMessages();
      this.props.resetErrorMessages();
    }
  }

  render = () => {
    const props = this.props;
    const {
      match, attorneysOfJudge, attorneyAppealsLoadingState, selectedTasks, success, error
    } = props;
    const { attorneyId } = match.params;

    if (!(attorneyId in attorneyAppealsLoadingState) || attorneyAppealsLoadingState[attorneyId].state === 'LOADING') {
      return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
    }

    if (attorneyAppealsLoadingState[attorneyId].state === 'FAILED') {
      const { error: loadingError } = attorneyAppealsLoadingState[attorneyId];

      if (!loadingError.response) {
        return <StatusMessage title="Timeout">Error fetching cases</StatusMessage>;
      }

      return <StatusMessage title={loadingError.response.statusText}>Error fetching cases</StatusMessage>;
    }

    const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;

    return <React.Fragment>
      <h2>{attorneyName}'s Cases</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      <AssignWidget
        previousAssigneeId={attorneyId}
        onTaskAssignment={(params) => props.reassignTasksToUser(params)}
        selectedTasks={selectedTasks} />
      <TaskTable
        includeSelect
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDaysWaiting
        includeReaderLink
        includeNewDocsIcon
        tasks={this.props.tasksOfAttorney}
        userId={attorneyId} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { attorneyAppealsLoadingState, attorneysOfJudge } = state.queue;
  const {
    messages: {
      success,
      error
    }
  } = state.ui;
  const { attorneyId } = ownProps.match.params;

  return {
    tasksOfAttorney: getAssignedTasks(state, attorneyId),
    attorneyAppealsLoadingState,
    attorneysOfJudge,
    selectedTasks: selectedTasksSelector(state, attorneyId),
    success,
    error
  };
};

export default (connect(
  mapStateToProps,
  (dispatch) => (bindActionCreators({
    reassignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch)))(AssignedCasesPage): React.ComponentType<Params>);
