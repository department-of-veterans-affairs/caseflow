import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import TaskTable from './components/TaskTable';
import {
  initialAssignTasksToUser,
  initialCamoAssignTasksToVhaProgramOffice,
  initialSpecialtyCaseTeamAssignTasksToUser
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
  camoAssignTasksSelector,
  specialtyCaseTeamAssignTasksSelector,
  isVhaCamoOrg,
  isSpecialtyCaseTeamOrg
} from './selectors';
import Alert from '../components/Alert';
import LoadingContainer from '../components/LoadingContainer';
import { LOGO_COLORS } from '../constants/AppConstants';
import { css } from 'glamor';
import querystring from 'querystring';
import { columnsFromConfig } from './queueTableUtils';
import { DEFAULT_QUEUE_TABLE_SORT } from './constants';

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
    const { userId, selectedTasks, success, error, userIsCamoEmployee, userIsSCTCoordinator } = this.props;
    let assignWidget;

    const commonAssignProps = {
      userId,
      previousAssigneeId: userId,
      selectedTasks,
    };

    if (userIsCamoEmployee) {
      assignWidget = <AssignToVhaProgramOfficeWidget
        {...commonAssignProps}
        onTaskAssignment={this.props.initialCamoAssignTasksToVhaProgramOffice} />;
    } else if (userIsSCTCoordinator) {
      assignWidget = <AssignToAttorneyWidget
        {...commonAssignProps}
        onTaskAssignment={this.props.initialSpecialtyCaseTeamAssignTasksToUser}
        selectedAssignee="OTHER"
        hidePrimaryAssignDropdown
        secondaryAssignDropdownLabel="Select an attorney"
      />;
    } else {
      assignWidget = <AssignToAttorneyWidget
        {...commonAssignProps}
        onTaskAssignment={this.props.initialAssignTasksToUser} />;
    }

    const HeadingTag = userIsSCTCoordinator ? 'h1' : 'h2';

    // Setup for backend paginated task retrieval
    const tabPaginationOptions = querystring.parse(window.location.search.slice(1));
    const queueConfig = this.props.queueConfig;
    const tabConfig = queueConfig.tabs?.[0] || {};
    const tabColumns = columnsFromConfig(queueConfig, tabConfig, []);

    if (tabConfig) {
      // Order all of the columns from the backend except badges so any included columns will be in front
      tabColumns.slice(1).forEach((obj) => {
        obj.order = 1;
      });

      // // Setup default sorting for the SCT assign page.
      // If there is no sort by column in the pagination options, then use the tab config default sort
      if (!tabPaginationOptions.sort_by) {
        tabPaginationOptions.sort_by = tabConfig.defaultSort?.sortColName;
        tabPaginationOptions.order = tabConfig.defaultSort?.sortAscending ? 'asc' : 'desc';
      }

    }

    const includedColumnProps = {
      includeBadges: true,
      includeSelect: true,
      includeDetailsLink: true,
      includeType: true,
      includeDocketNumber: true,
      includeIssueCount: true,
      includeDaysWaiting: true,
      includeIssueTypes: Boolean(userIsCamoEmployee),
      includeReaderLink: true,
      includeNewDocsIcon: true,
    };

    const specialtyCaseTeamProps = {
      includeSelect: true,
      customColumns: tabColumns,
      taskPagesApiEndpoint: tabConfig.task_page_endpoint_base_path,
      useTaskPagesApi: true,
      tabPaginationOptions,
      useReduxCache: true,
    };

    return <React.Fragment>
      <HeadingTag {...css({ display: 'inline-block' })}>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</HeadingTag>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      <div {...assignSectionStyling}>
        <React.Fragment>
          <div {...assignAndRequestStyling}>
            {assignWidget}
            {!userIsCamoEmployee && !userIsSCTCoordinator && <RequestDistributionButton userId={userId} />}
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
              {...(!userIsSCTCoordinator && { ...includedColumnProps })}
              {...(userIsSCTCoordinator && { ...specialtyCaseTeamProps })}
              tasks={userIsSCTCoordinator ? [] : this.props.tasks}
              userId={userId}
              defaultSort={DEFAULT_QUEUE_TABLE_SORT}
              {...(userIsCamoEmployee ? { preserveQueueFilter: true } : {})}
            />
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
      pendingDistribution,
      queueConfig
    },
    ui: {
      userIsCamoEmployee,
      userIsSCTCoordinator,
      messages: {
        success,
        error
      }
    }
  } = state;

  let taskSelector = judgeAssignTasksSelector(state);
  let fromReduxTasks = true;

  if (userIsCamoEmployee && isVhaCamoOrg(state)) {
    taskSelector = camoAssignTasksSelector(state);
  }

  if (userIsSCTCoordinator && isSpecialtyCaseTeamOrg(state)) {
    taskSelector = specialtyCaseTeamAssignTasksSelector(state);
    fromReduxTasks = false;
  }

  return {
    tasks: taskSelector,
    isTaskAssignedToUserSelected,
    pendingDistribution,
    queueConfig,
    distributionLoading: pendingDistribution !== null,
    distributionCompleteCasesLoading: pendingDistribution && pendingDistribution.status === 'completed',
    selectedTasks: selectedTasksSelector(state, ownProps.userId, fromReduxTasks),
    success,
    error,
    userIsCamoEmployee: isVhaCamoOrg(state),
    userIsSCTCoordinator: isSpecialtyCaseTeamOrg(state)
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
  initialSpecialtyCaseTeamAssignTasksToUser: PropTypes.func,
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
  queueConfig: PropTypes.object,
  userIsCamoEmployee: PropTypes.bool,
  userIsSCTCoordinator: PropTypes.bool,
  isVhaCamoOrg: PropTypes.bool,
  isSpecialtyCaseTeamOrg: PropTypes.bool,
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    initialCamoAssignTasksToVhaProgramOffice,
    initialSpecialtyCaseTeamAssignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage));
