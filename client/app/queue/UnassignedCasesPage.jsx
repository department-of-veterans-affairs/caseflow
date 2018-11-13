// @flow
import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import TaskTable from './components/TaskTable';
import {
  initialAssignTasksToUser,
  requestDistribution
} from './QueueActions';
import AssignWidget from './components/AssignWidget';
import { JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE } from '../../COPY.json';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import { judgeAssignTasksSelector, selectedTasksSelector } from './selectors';
import type { Task, TaskWithAppeal } from './types/models';
import Alert from '../components/Alert';
import Button from '../components/Button';
import LoadingContainer from '../components/LoadingContainer';
import { LOGO_COLORS } from '../constants/AppConstants';
import type { UiStateMessage } from './types/state';
import { css } from 'glamor';

type Params = {|
  userId: string,
|};

type Props = Params & {|
  // Props
  featureToggles: Object,
  selectedTasks: Array<Task>,
  error: ?UiStateMessage,
  success: ?UiStateMessage,
  tasks: Array<TaskWithAppeal>,
  distributionLoading: Boolean,
  distributionCompleteCasesLoading: Boolean,
  // Action creators
  initialAssignTasksToUser: typeof initialAssignTasksToUser,
  requestDistribution: typeof requestDistribution,
  resetErrorMessages: typeof resetErrorMessages,
  resetSuccessMessages: typeof resetSuccessMessages
|};

const assignSectionStyling = css({ marginTop: '30px' });
const loadingContainerStyling = css({ marginTop: '-2em' });

class UnassignedCasesPage extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  requestDistributionSubmit = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
    this.props.requestDistribution(this.props.userId);
  }

  render = () => {
    const { userId, featureToggles, selectedTasks, success, error } = this.props;

    return <React.Fragment>
      <h2>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      {!featureToggles.automatic_case_distribution &&
        <React.Fragment>
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
        </React.Fragment>
      }
      {featureToggles.automatic_case_distribution &&
        <div {...assignSectionStyling}>
          {this.props.tasks.length > 0 || this.props.distributionCompleteCasesLoading ? (
            <React.Fragment>
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
              {this.props.distributionCompleteCasesLoading &&
                <div {...loadingContainerStyling}>
                  <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
                    <div className="cf-image-loader"></div>
                    <p className="cf-txt-c">Loading new cases&hellip;</p>
                  </LoadingContainer>
                </div>
              }
            </React.Fragment>
          ) : (
            <Button
              name="Request cases"
              onClick={this.requestDistributionSubmit}
              loading={this.props.distributionLoading}
              loadingText="Requesting cases&hellip;"
            />
          )}
        </div>
      }
    </React.Fragment>;
  }
}

const mapStateToProps = (state, ownProps) => {
  const {
    queue: {
      isTaskAssignedToUserSelected,
      pendingDistribution
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
    pendingDistribution,
    distributionLoading: pendingDistribution !== null,
    distributionCompleteCasesLoading: pendingDistribution && pendingDistribution.status === "completed",
    featureToggles,
    selectedTasks: selectedTasksSelector(state, ownProps.userId),
    success,
    error
  };
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    requestDistribution,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage): React.ComponentType<Params>);
