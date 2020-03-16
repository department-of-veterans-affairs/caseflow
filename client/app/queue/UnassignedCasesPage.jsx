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
import Alert from '../components/Alert';
import LoadingContainer from '../components/LoadingContainer';
import { LOGO_COLORS } from '../constants/AppConstants';
import { css } from 'glamor';

const assignSectionStyling = css({ marginTop: '30px' });
const loadingContainerStyling = css({ marginTop: '-2em' });

class UnassignedCasesPage extends React.PureComponent {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  render = () => {
    const { userId, selectedTasks, success, error } = this.props;

    return <React.Fragment>
      <h2>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      <div {...assignSectionStyling}>
        <React.Fragment>
          <AssignWidget
            userId={userId}
            previousAssigneeId={userId}
            onTaskAssignment={this.props.initialAssignTasksToUser}
            selectedTasks={selectedTasks}
            showRequestCasesButton />
          {this.props.distributionCompleteCasesLoading &&
            <div {...loadingContainerStyling}>
              <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
                <div className="cf-image-loader"></div>
                <p className="cf-txt-c">Loading new cases&hellip;</p>
              </LoadingContainer>
            </div>
          }
          {!this.props.distributionCompleteCasesLoading &&
            <TaskTable
              includeBadges
              includeSelect
              includeDetailsLink
              includeType
              includeDocketNumber
              includeIssueCount
              includeDaysWaiting
              includeReaderLink
              includeNewDocsIcon
              tasks={this.props.tasks}
              userId={userId} />
          }
        </React.Fragment>
      </div>
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
    distributionCompleteCasesLoading: pendingDistribution && pendingDistribution.status === 'completed',
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

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage));
