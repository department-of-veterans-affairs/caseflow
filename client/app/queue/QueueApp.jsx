/* eslint-disable max-lines */
import querystring from 'querystring';
import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, BrowserRouter, Switch } from 'react-router-dom';
import StringUtil from '../util/StringUtil';

import {
  setCanEditAod,
  setFeatureToggles,
  setUserRole,
  setUserCssId,
  setUserIsVsoEmployee,
  setFeedbackUrl,
  setOrganizations
} from './uiReducer/uiActions';

import ScrollToTop from '../components/ScrollToTop';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import CaseSearchLink from '../components/CaseSearchLink';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import QueueLoadingScreen from './QueueLoadingScreen';
import CaseDetailsLoadingScreen from './CaseDetailsLoadingScreen';
import AttorneyTaskListView from './AttorneyTaskListView';
import ColocatedTaskListView from './ColocatedTaskListView';
import JudgeDecisionReviewTaskListView from './JudgeDecisionReviewTaskListView';
import JudgeAssignTaskListView from './JudgeAssignTaskListView';
import EvaluateDecisionView from './caseEvaluation/EvaluateDecisionView';
import AddColocatedTaskView from './AddColocatedTaskView';
import CompleteTaskModal from './components/CompleteTaskModal';
import UpdateTaskStatusAssignRegionalOfficeModal from './components/UpdateTaskStatusAssignRegionalOfficeModal';
import CancelTaskModal from './components/CancelTaskModal';
import AssignHearingModal from './components/AssignHearingModal';
import PostponeHearingModal from './components/PostponeHearingModal';
import ChangeHearingDispositionModal from './ChangeHearingDispositionModal';
import CreateChangeHearingDispositionTaskModal from './CreateChangeHearingDispositionTaskModal';
import AdvancedOnDocketMotionView from './AdvancedOnDocketMotionView';
import AssignToAttorneyModalView from './AssignToAttorneyModalView';
import AssignToView from './AssignToView';
import CreateMailTaskDialog from './CreateMailTaskDialog';
import AddJudgeTeamModal from './AddJudgeTeamModal';
import AddVsoModal from './AddVsoModal';
import AddPrivateBarModal from './AddPrivateBarModal';
import LookupParticipantIdModal from './LookupParticipantIdModal';
import PostponeHearingTaskModal from './PostponeHearingTaskModal';
import ChangeTaskTypeModal from './ChangeTaskTypeModal';
import StartHoldModal from './components/StartHoldModal';
import EndHoldModal from './components/EndHoldModal';
import BulkAssignModal from './components/BulkAssignModal';

import CaseListView from './CaseListView';
import CaseDetailsView from './CaseDetailsView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsContainer from './SelectDispositionsContainer';
import SelectSpecialIssuesView from './SelectSpecialIssuesView';
import SpecialIssueLoadingScreen from './SpecialIssueLoadingScreen';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';
import OrganizationQueue from './OrganizationQueue';
import OrganizationUsers from './OrganizationUsers';
import OrganizationQueueLoadingScreen from './OrganizationQueueLoadingScreen';
import TeamManagement from './TeamManagement';
import UserManagement from './UserManagement';

import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_TITLES } from './constants';
import COPY from '../../COPY';
import TASK_ACTIONS from '../../constants/TASK_ACTIONS';
import TASK_STATUSES from '../../constants/TASK_STATUSES';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES';
import { FlashAlerts } from '../nonComp/components/Alerts';

import { PulacCerulloReminderModal } from './pulacCerullo/PulacCerulloReminderModal';
import { motionToVacateRoutes } from './mtv/motionToVacateRoutes';

class QueueApp extends React.PureComponent {
  componentDidMount = () => {
    this.props.setCanEditAod(this.props.canEditAod);
    this.props.setFeatureToggles(this.props.featureToggles);
    this.props.setUserRole(this.props.userRole);
    this.props.setUserCssId(this.props.userCssId);
    this.props.setOrganizations(this.props.organizations);
    this.props.setUserIsVsoEmployee(this.props.userIsVsoEmployee);
    this.props.setFeedbackUrl(this.props.feedbackUrl);
    if (this.props.hasCaseDetailsRole && document.getElementById('page-title').innerHTML === 'Queue') {
      document.getElementById('page-title').innerHTML = 'Search';
    }
  };

  routedSearchResults = (props) => {
    const veteranIdsParameter =
      props.match.params.caseflowVeteranIds || querystring.parse(props.location.search.replace(/^\?/, '')).veteran_ids;
    let caseflowVeteranIds;

    if (veteranIdsParameter) {
      caseflowVeteranIds = veteranIdsParameter.split(',');
    }

    return <CaseListView caseflowVeteranIds={caseflowVeteranIds} />;
  };

  viewForUserRole = () => {
    const { userRole } = this.props;

    if (userRole === USER_ROLE_TYPES.attorney) {
      return <AttorneyTaskListView />;
    } else if (userRole === USER_ROLE_TYPES.judge) {
      return <JudgeDecisionReviewTaskListView {...this.props} />;
    }

    return <ColocatedTaskListView />;
  };

  routedQueueList = () => (
    <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>{this.viewForUserRole()}</QueueLoadingScreen>
  );

  routedJudgeQueueList = (label) => ({ match }) => (
    <QueueLoadingScreen
      {...this.propsForQueueLoadingScreen()}
      match={match}
      userRole={USER_ROLE_TYPES.judge}
      loadAttorneys={label === 'assign'}
    >
      {label === 'assign' ? (
        <JudgeAssignTaskListView {...this.props} match={match} />
      ) : (
        <JudgeDecisionReviewTaskListView {...this.props} />
      )}
    </QueueLoadingScreen>
  );

  routedQueueDetail = (props) => (
    <CaseDetailsView
      appealId={props.match.params.appealId}
      userCanAccessReader={!this.props.hasCaseDetailsRole && !this.props.userCanViewHearingSchedule}
    />
  );

  routedQueueDetailWithLoadingScreen = (props) => (
    <CaseDetailsLoadingScreen {...this.propsForQueueLoadingScreen()} appealId={props.match.params.appealId}>
      {this.routedQueueDetail(props)}
    </CaseDetailsLoadingScreen>
  );

  routedSubmitDecision = (props) => (
    <SubmitDecisionView
      appealId={props.match.params.appealId}
      taskId={props.match.params.taskId}
      checkoutFlow={props.match.params.checkoutFlow}
      nextStep="/queue"
    />
  );

  routedSelectDispositions = (props) => (
    <SelectDispositionsContainer
      appealId={props.match.params.appealId}
      taskId={props.match.params.taskId}
      checkoutFlow={props.match.params.checkoutFlow}
    />
  );

  routedSelectSpecialIssues = (props) => {
    const { appealId, checkoutFlow, taskId } = props.match.params;

    return (
      <SpecialIssueLoadingScreen appealExternalId={appealId}>
        <SelectSpecialIssuesView
          appealId={appealId}
          taskId={taskId}
          prevStep={`/queue/appeals/${appealId}`}
          nextStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`}
        />
      </SpecialIssueLoadingScreen>
    );
  };

  routedAddEditIssue = (props) => {
    const { appealId, checkoutFlow, taskId } = props.match.params;

    return (
      <AddEditIssueView
        nextStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`}
        prevStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`}
        {...props.match.params}
      />
    );
  };

  routedSetIssueRemandReasons = (props) => {
    const { appealId, checkoutFlow, taskId } = props.match.params;

    return (
      <SelectRemandReasonsView
        prevStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`}
        {...props.match.params}
      />
    );
  };

  routedEvaluateDecision = (props) => <EvaluateDecisionView nextStep="/queue" {...props.match.params} />;

  routedAddColocatedTask = (props) => <AddColocatedTaskView {...props.match.params} role={this.props.userRole} />;

  routedAdvancedOnDocketMotion = (props) => <AdvancedOnDocketMotionView {...props.match.params} />;

  routedAssignToAttorney = (props) => <AssignToAttorneyModalView userId={this.props.userId} match={props.match} />;

  routedAssignToSingleTeam = (props) => <AssignToView isTeamAssign assigneeAlreadySelected {...props.match.params} />;

  routedAssignToTeam = (props) => <AssignToView isTeamAssign {...props.match.params} />;

  routedCreateMailTask = (props) => <CreateMailTaskDialog {...props.match.params} />;

  routedAssignToUser = (props) => <AssignToView {...props.match.params} />;

  routedPulacCerulloReminder = (props) => {
    const { appealId, taskId } = props.match.params;
    const pulacRoute = `/queue/appeals/${appealId}/tasks/${taskId}/${TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.value}`;
    const dispatchRoute = `/queue/appeals/${appealId}/tasks/${taskId}/dispatch_decision/dispositions`;

    return (
      <PulacCerulloReminderModal
        {...props.match.params}
        onCancel={() => props.history.goBack()}
        onSubmit={({ hasCavc }) => props.history.push(hasCavc ? pulacRoute : dispatchRoute)}
      />
    );
  };

  routedAssignToPulacCerullo = (props) => <AssignToView isTeamAssign assigneeAlreadySelected {...props.match.params} />;

  routedReassignToUser = (props) => <AssignToView isReassignAction {...props.match.params} />;

  routedCompleteTaskModal = (props) => <CompleteTaskModal modalType="mark_task_complete" {...props.match.params} />;

  routedCancelTaskModal = (props) => <CancelTaskModal {...props.match.params} />;

  routedUpdateTaskAndAssignRegionalOfficeModal = (updateStatusTo) => (props) => (
    <UpdateTaskStatusAssignRegionalOfficeModal updateStatusTo={updateStatusTo} {...props.match.params} />
  );

  routedAssignHearingModal = (props) => <AssignHearingModal userId={this.props.userId} {...props.match.params} />;

  routedPostponeHearingModal = (props) => <PostponeHearingModal userId={this.props.userId} {...props.match.params} />;

  routedChangeTaskTypeModal = (props) => <ChangeTaskTypeModal {...props.match.params} />;

  routedChangeHearingDisposition = (props) => <ChangeHearingDispositionModal {...props.match.params} />;

  routedCreateChangeHearingDispositionTask = (props) => (
    <CreateChangeHearingDispositionTaskModal {...props.match.params} />
  );

  routedSendColocatedTaskModal = (props) => {
    return <CompleteTaskModal modalType="send_colocated_task" {...props.match.params} />;
  };

  routedBulkAssignTaskModal = (props) => {
    const { match } = props;
    const pageRoute = match.path.replace('modal/bulk_assign_tasks', '');

    return <BulkAssignModal {...props} onCancel={() => props.history.push(pageRoute)} />;
  };

  routedOrganization = (props) => {
    const {
      match: { url }
    } = props;

    return (
      <OrganizationQueueLoadingScreen urlToLoad={`${url}/tasks`}>
        <OrganizationQueue {...this.props} paginationOptions={querystring.parse(window.location.search.slice(1))} />
      </OrganizationQueueLoadingScreen>
    );
  };

  routedOrganizationUsers = (props) => <OrganizationUsers {...props.match.params} />;

  routedTeamManagement = (props) => <TeamManagement {...props.match.params} />;

  routedUserManagement = (props) => <UserManagement {...props.match.params} />;

  routedAddJudgeTeam = (props) => <AddJudgeTeamModal {...props.match.params} />;

  routedAddVsoModal = (props) => <AddVsoModal {...props.match.params} />;

  routedAddPrivateBarModal = (props) => <AddPrivateBarModal {...props.match.params} />;

  routedLookupParticipantIdModal = (props) => <LookupParticipantIdModal {...props.match.params} />;

  routedPostponeHearingTaskModal = (props) => <PostponeHearingTaskModal {...props.match.params} />;

  routedStartHoldModal = (props) => <StartHoldModal {...props.match.params} />;

  routedEndHoldModal = (props) => <EndHoldModal {...props.match.params} />;

  queueName = () => (this.props.userRole === USER_ROLE_TYPES.attorney ? 'Your Queue' : 'Review Cases');

  propsForQueueLoadingScreen = () => {
    const { userId, userCssId, userRole } = this.props;

    return {
      userId,
      userCssId,
      userRole
    };
  };

  render = () => (
    <BrowserRouter>
      <NavigationBar
        wideApp
        defaultUrl={this.props.caseSearchHomePage || this.props.hasCaseDetailsRole ? '/search' : '/queue'}
        userDisplayName={this.props.userDisplayName}
        dropdownUrls={this.props.dropdownUrls}
        applicationUrls={this.props.applicationUrls}
        logoProps={{
          overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
          accentColor: LOGO_COLORS.QUEUE.ACCENT
        }}
        rightNavElement={<CaseSearchLink />}
        appName="Queue"
      >
        <AppFrame wideApp>
          <ScrollToTop />
          <div className="cf-wide-app">
            {this.props.flash && <FlashAlerts flash={this.props.flash} />}

            {/* Base/page (non-modal) routes */}
            <Switch>
              <PageRoute
                exact
                path={['/search', '/cases/:caseflowVeteranIds']}
                title="Caseflow"
                render={this.routedSearchResults}
              />
              <PageRoute exact path="/queue" title={`${this.queueName()}  | Caseflow`} render={this.routedQueueList} />
              <PageRoute
                exact
                path="/queue/:userId"
                title={`${this.queueName()}  | Caseflow`}
                render={this.routedQueueList}
              />
              <PageRoute
                exact
                path="/queue/:userId/review"
                title="Review Cases | Caseflow"
                render={this.routedJudgeQueueList('review')}
              />
              <PageRoute
                path="/queue/:userId/assign"
                title="Unassigned Cases | Caseflow"
                render={this.routedJudgeQueueList('assign')}
              />

              <PageRoute
                exact
                path="/queue/appeals/:appealId"
                title="Case Details | Caseflow"
                render={this.routedQueueDetailWithLoadingScreen}
              />
              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/modal/:modalType"
                title="Case Details | Caseflow"
                render={this.routedQueueDetail}
              />
              <PageRoute
                exact
                path={
                  '/queue/appeals/:appealId/tasks/:taskId/' +
                  ':checkoutFlow(draft_decision|dispatch_decision|omo_request)/submit'
                }
                title={(props) => {
                  let reviewActionType = props.match.params.checkoutFlow;

                  // eslint-disable-next-line default-case
                  switch (this.props.reviewActionType) {
                  case DECISION_TYPES.OMO_REQUEST:
                    reviewActionType = 'OMO';
                    break;
                  case DECISION_TYPES.DRAFT_DECISION:
                    reviewActionType = 'Draft Decision';
                    break;
                  case DECISION_TYPES.DISPATCH:
                    reviewActionType = 'to Dispatch';
                    break;
                  }

                  return `Draft Decision | Submit ${reviewActionType}`;
                }}
                render={this.routedSubmitDecision}
              />
              <PageRoute
                exact
                path={
                  '/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/' +
                  'dispositions/:action(add|edit)/:issueId?'
                }
                title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
                render={this.routedAddEditIssue}
              />
              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/remands"
                title={`Draft Decision | ${PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()]}`}
                render={this.routedSetIssueRemandReasons}
              />
              <PageRoute
                exact
                path={[
                  '/queue/appeals/:appealId/tasks/:taskId',
                  ':checkoutFlow(draft_decision|dispatch_decision)/dispositions'
                ].join('/')}
                title={`Draft Decision | ${PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()]}`}
                render={this.routedSelectDispositions}
              />
              <PageRoute
                exact
                path={[
                  '/queue/appeals/:appealId/tasks/:taskId/',
                  ':checkoutFlow(draft_decision|dispatch_decision)/special_issues'
                ].join('')}
                title={`Draft Decision | ${COPY.SPECIAL_ISSUES_PAGE_TITLE}`}
                render={this.routedSelectSpecialIssues}
              />
              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(dispatch_decision|omo_request)/evaluate"
                title="Evaluate Decision | Caseflow"
                render={this.routedEvaluateDecision}
              />
              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/colocated_task"
                title="Add Colocated Task | Caseflow"
                render={this.routedAddColocatedTask}
              />

              <PageRoute
                exact
                path="/organizations/:organization/users"
                title="Organization Users | Caseflow"
                render={this.routedOrganizationUsers}
              />
              <PageRoute
                path="/organizations/:organization"
                title="Organization Queue | Caseflow"
                render={this.routedOrganization}
              />

              <PageRoute
                path="/team_management"
                title="Team Management | Caseflow"
                render={this.routedTeamManagement}
              />
              <PageRoute
                path="/user_management"
                title="User Management | Caseflow"
                render={this.routedUserManagement}
              />

              {motionToVacateRoutes.page}
            </Switch>

            {/* Modal routes are in their own Switch so they will display above the base routes */}
            <Switch>
              <Route
                path="/queue/appeals/:appealId/modal/advanced_on_docket_motion"
                render={this.routedAdvancedOnDocketMotion}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_ATTORNEY.value}`}
                render={this.routedAssignToAttorney}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_HEARING_ADMIN_MEMBER.value}`}
                render={this.routedReassignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.value}`}
                render={this.routedAssignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_PERSON.value}`}
                render={this.routedAssignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.value}`}
                render={this.routedAssignToSingleTeam}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SEND_TO_TRANSLATION.value}`}
                render={this.routedAssignToSingleTeam}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.value}`}
                render={this.routedPostponeHearingTaskModal}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_TEAM.value}`}
                render={this.routedAssignToTeam}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CREATE_MAIL_TASK.value}`}
                render={this.routedCreateMailTask}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.REASSIGN_TO_JUDGE.value}`}
                render={this.routedReassignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.REASSIGN_TO_PERSON.value}`}
                render={this.routedReassignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.QR_RETURN_TO_JUDGE.value}`}
                render={this.routedAssignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_QR_RETURN_TO_ATTORNEY.value}`}
                render={this.routedAssignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.DISPATCH_RETURN_TO_JUDGE.value}`}
                render={this.routedAssignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_DISPATCH_RETURN_TO_ATTORNEY.value}`}
                render={this.routedAssignToUser}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CHANGE_HEARING_DISPOSITION.value}`}
                render={this.routedChangeHearingDisposition}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.value
                }`}
                render={this.routedCreateChangeHearingDispositionTask}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.PLACE_TIMED_HOLD.value}`}
                render={this.routedStartHoldModal}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.END_TIMED_HOLD.value}`}
                render={this.routedEndHoldModal}
              />
              <Route
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.value}`}
                render={this.routedAssignToUser}
              />

              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/place_hold"
                title="Place Hold | Caseflow"
                render={this.routedColocatedPlaceHold}
              />
              <PageRoute
                exact
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.MARK_COMPLETE.value}`}
                title="Mark Task Complete | Caseflow"
                render={this.routedCompleteTaskModal}
              />
              <PageRoute
                exact
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.value}`}
                title="Assign to Pulac-Cerullo | Caseflow"
                render={this.routedAssignToPulacCerullo}
              />
              <PageRoute
                exact
                path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.JUDGE_CHECKOUT_PULAC_CERULLO_REMINDER.value
                }`}
                title="Assign to Pulac-Cerullo | Caseflow"
                render={this.routedPulacCerulloReminder}
              />
              <PageRoute
                path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.value
                }`}
                title="Cancel Task and Assign Regional Office | Caseflow"
                render={this.routedUpdateTaskAndAssignRegionalOfficeModal(TASK_STATUSES.cancelled)}
              />
              <PageRoute
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.value}`}
                title="Send to Schedule Veteran List | Caseflow"
                render={this.routedUpdateTaskAndAssignRegionalOfficeModal(TASK_STATUSES.completed)}
              />
              <PageRoute
                exact
                path={
                  '/queue/appeals/:appealId/tasks/:taskId/' +
                  `(${TASK_ACTIONS.WITHDRAW_HEARING.value}|${TASK_ACTIONS.CANCEL_TASK.value})`
                }
                title="Cancel Task | Caseflow"
                render={this.routedCancelTaskModal}
              />
              <PageRoute
                exact
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SCHEDULE_VETERAN.value}`}
                title="Assign Hearing | Caseflow"
                render={this.routedAssignHearingModal}
              />
              <PageRoute
                exact
                path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.POSTPONE_HEARING.value}`}
                title="Postpone Hearing | Caseflow"
                render={this.routedPostponeHearingModal}
              />
              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/modal/send_colocated_task"
                title="Mark Task Complete | Caseflow"
                render={this.routedSendColocatedTaskModal}
              />
              <PageRoute
                exact
                path="/queue/appeals/:appealId/tasks/:taskId/modal/change_task_type"
                title="Change Task Type | Caseflow"
                render={this.routedChangeTaskTypeModal}
              />

              <Route
                path="/organizations/:organization/modal/bulk_assign_tasks"
                render={this.routedBulkAssignTaskModal}
              />

              <Route path="/team_management/add_judge_team" render={this.routedAddJudgeTeam} />
              <Route path="/team_management/add_vso" render={this.routedAddVsoModal} />
              <Route path="/team_management/add_private_bar" render={this.routedAddPrivateBarModal} />
              <Route path="/team_management/lookup_participant_id" render={this.routedLookupParticipantIdModal} />

              {motionToVacateRoutes.modal}
            </Switch>
          </div>
        </AppFrame>
        <Footer wideApp appName="" feedbackUrl={this.props.feedbackUrl} buildDate={this.props.buildDate} />
      </NavigationBar>
    </BrowserRouter>
  );
}

QueueApp.propTypes = {
  userDisplayName: PropTypes.string.isRequired,
  feedbackUrl: PropTypes.string.isRequired,
  userId: PropTypes.number.isRequired,
  userRole: PropTypes.string.isRequired,
  userCssId: PropTypes.string.isRequired,
  dropdownUrls: PropTypes.array,
  buildDate: PropTypes.string,
  setCanEditAod: PropTypes.func,
  canEditAod: PropTypes.bool,
  setFeatureToggles: PropTypes.func,
  featureToggles: PropTypes.object,
  setUserRole: PropTypes.func,
  setUserCssId: PropTypes.func,
  setOrganizations: PropTypes.func,
  organizations: PropTypes.array,
  setUserIsVsoEmployee: PropTypes.func,
  userIsVsoEmployee: PropTypes.bool,
  setFeedbackUrl: PropTypes.func,
  hasCaseDetailsRole: PropTypes.bool,
  caseSearchHomePage: PropTypes.bool,
  applicationUrls: PropTypes.array,
  flash: PropTypes.array,
  reviewActionType: PropTypes.string,
  userCanViewHearingSchedule: PropTypes.bool
};

const mapStateToProps = (state) => ({
  reviewActionType: state.queue.stagedChanges.taskDecision.type
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setCanEditAod,
      setFeatureToggles,
      setUserRole,
      setUserCssId,
      setUserIsVsoEmployee,
      setFeedbackUrl,
      setOrganizations
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(QueueApp);
