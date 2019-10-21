import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import StatusMessage from '../components/StatusMessage';
import TaskTable from './components/TaskTable';
import SmallLoader from '../components/SmallLoader';
import { LOGO_COLORS } from '../constants/AppConstants';
import { reassignTasksToUser, fetchTasksAndAppealsOfAttorney, fetchAmaTasksOfUser } from './QueueActions';
import { selectedTasksSelector, getAssignedTasks } from './selectors';
import AssignWidget from './components/AssignWidget';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import Alert from '../components/Alert';

class AssignedCasesPage extends React.Component {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
    this.fetchAttorneyTasks();
  }

  componentDidUpdate = (prevProps) => {
    const { attorneyId: prevAttorneyId } = prevProps.match.params;
    const { attorneyId } = this.props.match.params;

    if (attorneyId !== prevAttorneyId) {
      this.props.resetSuccessMessages();
      this.props.resetErrorMessages();
      this.fetchAttorneyTasks();
    }
  }

  fetchAttorneyTasks = () => {
    const { match, attorneyAppealsLoadingState } = this.props;
    const { attorneyId } = match.params;

    if (!attorneyAppealsLoadingState || !(attorneyId in attorneyAppealsLoadingState)) {
      this.props.fetchTasksAndAppealsOfAttorney(attorneyId, { role: 'judge' });
      this.props.fetchAmaTasksOfUser(attorneyId, 'attorney');
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
        includeHearingBadge
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

AssignedCasesPage.propTypes = {
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  match: PropTypes.object,
  attorneyAppealsLoadingState: PropTypes.object,
  fetchTasksAndAppealsOfAttorney: PropTypes.func,
  fetchAmaTasksOfUser: PropTypes.func,
  attorneysOfJudge: PropTypes.array,
  reassignTasksToUser: PropTypes.func,
  tasksOfAttorney: PropTypes.array,
  selectedTasks: PropTypes.array,
  success: PropTypes.object,
  error: PropTypes.object
};

const mapStateToProps = (state, ownProps) => {
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
    resetSuccessMessages,
    fetchTasksAndAppealsOfAttorney,
    fetchAmaTasksOfUser
  }, dispatch)))(AssignedCasesPage));
