// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import StatusMessage from '../components/StatusMessage';
import TaskTable from './components/TaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { reassignTasksToUser } from './QueueActions';
import { selectedTasksSelector, getAssignedAppeals } from './selectors';
import AssignWidget from './components/AssignWidget';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import type { Task, LegacyAppeals } from './types/models';
import type { AttorneysOfJudge, AttorneyAppealsLoadingState, State } from './types/state';

type Params = {|
  match: Object
|};

type Props = Params & {|
  // From state
  attorneysOfJudge: AttorneysOfJudge,
  appealsOfAttorney: LegacyAppeals,
  featureToggles: Object,
  selectedTasks: Array<Task>,
  attorneyAppealsLoadingState: AttorneyAppealsLoadingState,
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
      match, attorneysOfJudge, attorneyAppealsLoadingState, featureToggles, selectedTasks
    } = props;
    const { attorneyId } = match.params;

    if (!(attorneyId in attorneyAppealsLoadingState) || attorneyAppealsLoadingState[attorneyId].state === 'LOADING') {
      return <SmallLoader message="Loading..." spinnerColor={LOGO_COLORS.QUEUE.ACCENT} />;
    }

    if (attorneyAppealsLoadingState[attorneyId].state === 'FAILED') {
      const { error } = attorneyAppealsLoadingState[attorneyId];

      if (!error.response) {
        return <StatusMessage title="Timeout">Error fetching cases</StatusMessage>;
      }

      return <StatusMessage title={error.response.statusText}>Error fetching cases</StatusMessage>;
    }

    const attorneyName = attorneysOfJudge.filter((attorney) => attorney.id.toString() === attorneyId)[0].full_name;

    return <React.Fragment>
      <h2>{attorneyName}'s Cases</h2>
      {featureToggles.judge_assignment_to_attorney &&
        <AssignWidget
          previousAssigneeId={attorneyId}
          onTaskAssignment={(params) => props.reassignTasksToUser(params)}
          selectedTasks={selectedTasks} />}
      <TaskTable
        includeSelect
        includeDetailsLink
        includeType
        includeDocketNumber
        includeIssueCount
        includeDocumentCount
        includeDaysWaiting
        appeals={this.props.appealsOfAttorney}
        userId={attorneyId} />
    </React.Fragment>;
  }
}

const mapStateToProps = (state: State, ownProps: Params) => {
  const { attorneyAppealsLoadingState, attorneysOfJudge } = state.queue;
  const { featureToggles } = state.ui;
  const { attorneyId } = ownProps.match.params;

  return {
    appealsOfAttorney: getAssignedAppeals(state, attorneyId),
    attorneyAppealsLoadingState,
    attorneysOfJudge,
    featureToggles,
    selectedTasks: selectedTasksSelector(state, attorneyId)
  };
};

export default (connect(
  mapStateToProps,
  (dispatch) => (bindActionCreators({
    reassignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch)))(AssignedCasesPage): React.ComponentType<Params>);
