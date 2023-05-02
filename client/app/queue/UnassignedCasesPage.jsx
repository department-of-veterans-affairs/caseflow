import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import TaskTable from './components/TaskTable';
import {
  initialAssignTasksToUser,
  initialCamoAssignTasksToVhaProgramOffice
} from './QueueActions';
import AssignToAttorneyWidget from './components/AssignToAttorneyWidget';
import AssignToVhaProgramOfficeWidget from './components/AssignToVhaProgramOfficeWidget';
import RequestDistributionButton from './components/RequestDistributionButton';
import { JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE } from '../../COPY';
import {
  resetErrorMessages,
  resetSuccessMessages
} from './uiReducer/uiActions';
import {
  judgeAssignTasksSelector,
  selectedTasksSelector,
  camoAssignTasksSelector
} from './selectors';
import Alert from '../components/Alert';
import LoadingContainer from '../components/LoadingContainer';
import { LOGO_COLORS } from '../constants/AppConstants';
import { css } from 'glamor';

const assignSectionStyling = css({ marginTop: '30px' });
const loadingContainerStyling = css({ marginTop: '-2em' });
const assignAndRequestStyling = css({
  display: 'flex',
  alignItems: 'center',
  flexWrap: 'wrap',
  '& > *': { marginRight: '1rem',
    marginTop: '0',
    marginBottom: '16px' } });

class UnassignedCasesPage extends React.PureComponent {
  componentDidMount = () => {
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  render = () => {
    const { userId, selectedTasks, success, error, userIsCamoEmployee } = this.props;
    let assignWidget;

    if (userIsCamoEmployee) {
      assignWidget = <AssignToVhaProgramOfficeWidget
        userId={userId}
        previousAssigneeId={userId}
        onTaskAssignment={this.props.initialCamoAssignTasksToVhaProgramOffice}
        selectedTasks={selectedTasks}
        showRequestCasesButton />;
    } else {
      assignWidget = <AssignToAttorneyWidget
        userId={userId}
        previousAssigneeId={userId}
        onTaskAssignment={this.props.initialAssignTasksToUser}
        selectedTasks={selectedTasks}
        showRequestCasesButton />;
    }

    return <React.Fragment>
      <h2 {...css({ display: 'inline-block' })}>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      <div {...assignSectionStyling}>
        <React.Fragment>
          <div {...assignAndRequestStyling}>
            {assignWidget}
            {!userIsCamoEmployee && <RequestDistributionButton userId={userId} />}
          </div>
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
              {...(userIsCamoEmployee ? { includeIssueTypes: true } : {})}
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
      userIsCamoEmployee,
      messages: {
        success,
        error
      }
    }
  } = state;

  let taskSelector = judgeAssignTasksSelector(state);

  if (userIsCamoEmployee) {
    taskSelector = camoAssignTasksSelector(state);
  }

  return {
    tasks: taskSelector,
    isTaskAssignedToUserSelected,
    pendingDistribution,
    distributionLoading: pendingDistribution !== null,
    distributionCompleteCasesLoading: pendingDistribution && pendingDistribution.status === 'completed',
    selectedTasks: selectedTasksSelector(state, ownProps.userId),
    success,
    error,
    userIsCamoEmployee
  };
};

UnassignedCasesPage.propTypes = {
  tasks: PropTypes.array,
  userId: PropTypes.number,
  userRole: PropTypes.string,
  selectedTasks: PropTypes.array,
  distributionCompleteCasesLoading: PropTypes.bool,
  initialAssignTasksToUser: PropTypes.func,
  initialCamoAssignTasksToVhaProgramOffice: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  userIsCamoEmployee: PropTypes.bool
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    initialCamoAssignTasksToVhaProgramOffice,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage));
