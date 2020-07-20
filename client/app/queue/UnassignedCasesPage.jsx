import * as React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import TaskTable from './components/TaskTable';
import {
  initialAssignTasksToUser
} from './QueueActions';
import AssignToAttorneyWidget from './components/AssignToAttorneyWidget';
import RequestDistributionButton from './components/RequestDistributionButton';
import { JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE } from '../../COPY';
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
    const { userId, selectedTasks, success, error } = this.props;

    return <React.Fragment>
      <h2>{JUDGE_QUEUE_UNASSIGNED_CASES_PAGE_TITLE}</h2>
      {error && <Alert type="error" title={error.title} message={error.detail} scrollOnAlert={false} />}
      {success && <Alert type="success" title={success.title} message={success.detail} scrollOnAlert={false} />}
      <div {...assignSectionStyling}>
        <React.Fragment>
          <div {...assignAndRequestStyling}>
            <AssignToAttorneyWidget
              userId={userId}
              previousAssigneeId={userId}
              onTaskAssignment={this.props.initialAssignTasksToUser}
              selectedTasks={selectedTasks}
              showRequestCasesButton />
            <RequestDistributionButton userId={userId} />
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

UnassignedCasesPage.propTypes = {
  tasks: PropTypes.array,
  userId: PropTypes.number,
  selectedTasks: PropTypes.array,
  distributionCompleteCasesLoading: PropTypes.bool,
  initialAssignTasksToUser: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  error: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  }),
  success: PropTypes.shape({
    title: PropTypes.string,
    detail: PropTypes.string
  })
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators({
    initialAssignTasksToUser,
    resetErrorMessages,
    resetSuccessMessages
  }, dispatch);

export default (connect(mapStateToProps, mapDispatchToProps)(UnassignedCasesPage));
