/* eslint-disable max-lines */

import querystring from 'querystring';
import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, Switch } from 'react-router-dom';
import StringUtil from '../util/StringUtil';

import {
  setCanEditAod,
  setCanEditNodDate,
  setUserIsCobAdmin,
  setCanViewOvertimeStatus,
  setCanEditCavcRemands,
  setCanEditCavcDashboards,
  setCanViewCavcDashboards,
  setFeatureToggles,
  setUserId,
  setUserRole,
  setUserCssId,
  setUserIsVsoEmployee,
  setUserIsCamoEmployee,
  setFeedbackUrl,
  setOrganizations,
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
import TeamAssignTaskListView from './TeamAssignTaskListView';
import EvaluateDecisionView from './caseEvaluation/EvaluateDecisionView';
import AddColocatedTaskView from './colocatedTasks/AddColocatedTaskView';
import BlockedAdvanceToJudgeView from './BlockedAdvanceToJudgeView';
import AddCavcRemandView from './cavc/AddCavcRemandView';
import AddCavcDatesModal from './cavc/AddCavcDatesModal';
import CompleteTaskModal from './components/CompleteTaskModal';
import UpdateTaskStatusAssignRegionalOfficeModal from './components/UpdateTaskStatusAssignRegionalOfficeModal';
import CancelTaskModal from './components/CancelTaskModal';
import InProgressTaskModal from './components/InProgressTaskModal';
import AssignHearingModal from './components/AssignHearingModal';
import PostponeHearingModal from './components/PostponeHearingModal';
import HearingScheduledInErrorModal from './components/HearingScheduledInErrorModal';
import ChangeHearingDispositionModal from './ChangeHearingDispositionModal';
import CreateChangeHearingDispositionTaskModal from './CreateChangeHearingDispositionTaskModal';
import AdvancedOnDocketMotionView from './AdvancedOnDocketMotionView';
import AssignToAttorneyModalView from './AssignToAttorneyModalView';
import AssignToView from './AssignToView';
import CreateMailTaskDialog from './CreateMailTaskDialog';
import AddJudgeTeamModal from './AddJudgeTeamModal';
import AddDvcTeamModal from './AddDvcTeamModal';
import AddVsoModal from './AddVsoModal';
import AddPrivateBarModal from './AddPrivateBarModal';
import LookupParticipantIdModal from './LookupParticipantIdModal';
import PostponeHearingTaskModal from './PostponeHearingTaskModal';
import ChangeTaskTypeModal from './ChangeTaskTypeModal';
import SetOvertimeStatusModal from './SetOvertimeStatusModal';
import StartHoldModal from './components/StartHoldModal';
import EndHoldModal from './components/EndHoldModal';
import BulkAssignModal from './components/BulkAssignModal';
import CompleteHearingPostponementRequestModal
  from './components/hearingMailRequestModals/CompleteHearingPostponementRequestModal';
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
import TeamManagement from './teamManagement/TeamManagement';
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
import { docketSwitchRoutes } from './docketSwitch/docketSwitchRoutes';
import { substituteAppellantRoutes } from './substituteAppellant/routes';
import ScheduleVeteran from '../hearings/components/ScheduleVeteran';
import HearingTypeConversionContainer from '../hearings/components/HearingTypeConversionContainer';
import HearingTypeConversionModal from '../hearings/components/HearingTypeConversionModal';
import CavcReviewExtensionRequestModal from './components/CavcReviewExtensionRequestModal';
import { PrivateRoute } from '../components/PrivateRoute';
import { editCavcRemandRoutes } from './cavc/editCavcRemandRoutes';
import EditAppellantInformation from './editAppellantInformation/EditAppellantInformation';
import EditPOAInformation from './editPOAInformation/EditPOAInformation';
import NotificationsView from './NotificationsView';
import CavcDashboard from './cavcDashboard/CavcDashboard';

class QueueApp extends React.PureComponent {
  componentDidMount = () => {
    this.props.setCanEditAod(this.props.canEditAod);
    this.props.setCanEditNodDate(this.props.userCanViewEditNodDate);
    this.props.setUserIsCobAdmin(this.props.userIsCobAdmin);
    this.props.setCanEditCavcRemands(this.props.canEditCavcRemands);
    this.props.setCanEditCavcDashboards(this.props.canEditCavcDashboards);
    this.props.setCanViewCavcDashboards(this.props.canViewCavcDashboards);
    this.props.setCanViewOvertimeStatus(this.props.userCanViewOvertimeStatus);
    this.props.setFeatureToggles(this.props.featureToggles);
    this.props.setUserId(this.props.userId);
    this.props.setUserRole(this.props.userRole);
    this.props.setUserCssId(this.props.userCssId);
    this.props.setOrganizations(this.props.organizations);
    this.props.setUserIsVsoEmployee(this.props.userIsVsoEmployee);
    this.props.setUserIsCamoEmployee(this.props.userIsCamoEmployee);
    this.props.setFeedbackUrl(this.props.feedbackUrl);
    if (
      this.props.hasCaseDetailsRole &&
      document.getElementById('page-title').innerHTML === 'Queue'
    ) {
      document.getElementById('page-title').innerHTML = 'Search';
    }
  };

  routedSearchResults = (props) => {
    const veteranIdsParameter =
      props.match.params.caseflowVeteranIds ||
      querystring.parse(props.location.search.replace(/^\?/, '')).veteran_ids;
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
    <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
      {this.viewForUserRole()}
    </QueueLoadingScreen>
  );

  routedTeamQueueList = (label) => ({ match }) => (
    <QueueLoadingScreen
      {...this.propsForQueueLoadingScreen()}
      match={match}
      userRole={this.props.userRole}
      loadJudgeData
      loadAttorneys={label === 'assign'}
      type={label}
    >
      {label === 'assign' ? (
        <TeamAssignTaskListView {...this.props} match={match} />
      ) : (
        <JudgeDecisionReviewTaskListView {...this.props} />
      )}
    </QueueLoadingScreen>
  );

  routedQueueDetail = (props) => (
    <CaseDetailsView
      userCanScheduleVirtualHearings={
        this.props.featureToggles.schedule_veteran_virtual_hearing
      }
      appealId={props.match.params.appealId}
      userCanAccessReader={
        !this.props.hasCaseDetailsRole && !this.props.userCanViewHearingSchedule
      }
      userCanEditUnrecognizedPOA={this.props.userCanEditUnrecognizedPOA}
      vsoVirtualOptIn={this.props.featureToggles.vso_virtual_opt_in}
    />
  );

  routedQueueDetailWithLoadingScreen = (props) => (
    <CaseDetailsLoadingScreen
      {...this.propsForQueueLoadingScreen()}
      appealId={props.match.params.appealId}
    >
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

  routedEvaluateDecision = (props) => (
    <EvaluateDecisionView nextStep="/queue"
      displayCaseTimelinessQuestion={this.props.featureToggles.das_case_timeliness}
      displayCaseTimelinessTimeline={this.props.featureToggles.das_case_timeline}
      {...props.match.params} />
  );

  routedAddColocatedTask = (props) => (
    <AddColocatedTaskView {...props.match.params} role={this.props.userRole} />
  );

  routedBlockedCaseMovement = (props) => (
    <BlockedAdvanceToJudgeView {...props.match.params} />
  );

  routedAddCavcRemand = (props) => (
    <AddCavcRemandView {...props.match.params} />
  );

  routedCavcDashboard = (props) => (
    <CavcDashboard
      appealId={props.match.params.appealId}
      history={props.history}
    />
  );

  routedAdvancedOnDocketMotion = (props) => (
    <AdvancedOnDocketMotionView {...props.match.params} />
  );

  routedAssignToAttorney = (props) => (
    <AssignToAttorneyModalView userId={this.props.userId} match={props.match} />
  );

  routedAssignToSingleTeam = (props) => (
    <AssignToView
      isTeamAssign
      assigneeAlreadySelected
      {...props.match.params}
    />
  );

  routedAssignToTeam = (props) => (
    <AssignToView isTeamAssign {...props.match.params} />
  );

  routedAssignToVhaProgramOffice = (props) => (
    <AssignToView isTeamAssign {...props.match.params} />
  );

  routedAssignToVhaRegionalOffice = (props) => (
    <AssignToView isTeamAssign {...props.match.params} />
  );

  routedAssignToEducationRpo = (props) => (
    <AssignToView isTeamAssign {...props.match.params} />
  );

  routedCreateMailTask = (props) => (
    <CreateMailTaskDialog {...props.match.params} />
  );

  routedAssignToUser = (props) => <AssignToView {...props.match.params} />;

  routedPulacCerulloReminder = (props) => {
    const { appealId, taskId } = props.match.params;
    const pulacRoute = `/queue/appeals/${appealId}/tasks/${taskId}/${TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.value
      }`;
    const dispatchRoute = `/queue/appeals/${appealId}/tasks/${taskId}/dispatch_decision/dispositions`;

    return (
      <PulacCerulloReminderModal
        {...props.match.params}
        onCancel={() => props.history.goBack()}
        onSubmit={({ hasCavc }) =>
          props.history.push(hasCavc ? pulacRoute : dispatchRoute)
        }
      />
    );
  };

  routedAssignToPulacCerullo = (props) => (
    <AssignToView
      isTeamAssign
      assigneeAlreadySelected
      {...props.match.params}
    />
  );
  routedNotifications = (props) => (
    <NotificationsView
      userCanScheduleVirtualHearings={
        this.props.featureToggles.schedule_veteran_virtual_hearing
      }
      appealId={props.match.params.appealId}
      userCanAccessReader={
        !this.props.hasCaseDetailsRole && !this.props.userCanViewHearingSchedule
      }
      userCanEditUnrecognizedPOA={this.props.userCanEditUnrecognizedPOA}
      vsoVirtualOptIn={this.props.featureToggles.vso_virtual_opt_in}
    />
  );
  routedNotificationsWithLoadingScreen = (props) => (
    <CaseDetailsLoadingScreen
      {...this.propsForQueueLoadingScreen()}
      appealId={props.match.params.appealId}
    >
      {this.routedNotifications(props)}
    </CaseDetailsLoadingScreen>
  );

  routedReassignToUser = (props) => (
    <AssignToView isReassignAction {...props.match.params} />
  );

  routedCompleteTaskModal = (props) => (
    <CompleteTaskModal modalType="mark_task_complete" {...props.match.params} />
  );

  routedCompleteTaskContestedClaimModal = (props) => (
    <CompleteTaskModal modalType="task_complete_contested_claim" {...props.match.params} />
  );

  routedProceedFinalNotificationLetterInitialModal = (props) => (
    <CompleteTaskModal modalType="proceed_final_notification_letter_initial" {...props.match.params} />
  );

  routedProceedFinalNotificationLetterPostHoldingModal = (props) => (
    <CompleteTaskModal modalType="proceed_final_notification_letter_post_holding" {...props.match.params} />
  );

  routedResendInitialNotificationLetterPostHoldingModal = (props) => (
    <CompleteTaskModal modalType="resend_initial_notification_letter_post_holding" {...props.match.params} />
  );

  routedResendInitialNotificationLetterFinalModal = (props) => (
    <CompleteTaskModal modalType="resend_initial_notification_letter_final" {...props.match.params} />
  );

  routedResendFinalNotificationLetterModal = (props) => (
    <CompleteTaskModal modalType="resend_final_notification_letter" {...props.match.params} />
  );

  routedVhaCompleteTaskModal = (props) => (
    <CompleteTaskModal modalType="ready_for_review" {...props.match.params} />
  );

  routedEmoSendToBoardIntakeForReviewModal = (props) => (
    <CompleteTaskModal modalType="emo_send_to_board_intake_for_review" {...props.match.params} />
  );

  routedVhaCaregiverSupportSendToBoardIntakeForReviewModal = (props) => (
    <CompleteTaskModal modalType="vha_caregiver_support_send_to_board_intake_for_review" {...props.match.params} />
  );

  routedRpoSendToBoardIntakeForReviewModal = (props) => (
    <CompleteTaskModal modalType="rpo_send_to_board_intake_for_review" {...props.match.params} />
  );

  routedDocketAppeal = (props) => (
    <CompleteTaskModal modalType="docket_appeal" {...props.match.params} />
  );

  routedBvaIntakeReturnToOrg = (props) => (
    <AssignToView isTeamAssign assigneeAlreadySelected {...props.match.params} />
  );

  routedReturnToCamo = (props) => (
    <CancelTaskModal {...props.match.params} />
  );

  routedReturnToProgramOffice = (props) => (
    <CancelTaskModal {...props.match.params} />
  );

  routedRpoReturnToEmo = (props) => (
    <CancelTaskModal {...props.match.params} />

  );

  routedCancelTaskModal = (props) => (
    <CancelTaskModal {...props.match.params} />
  );

  routedCancelLetterTaskModal = (props) => (
    <CancelTaskModal {...props.match.params} />
  );

  routedMarkTaskInProgressModal = (props) => (
    <InProgressTaskModal {...props.match.params} />
  );

  routedUpdateTaskAndAssignRegionalOfficeModal = (updateStatusTo) => (
    props
  ) => (
    <UpdateTaskStatusAssignRegionalOfficeModal
      updateStatusTo={updateStatusTo}
      {...props.match.params}
    />
  );

  routedScheduleVeteran = (props) => {
    const params = querystring.parse(props.location.search.replace(/^\?/, ''));

    return (
      <PrivateRoute
        authorized={this.props.userCanAssignHearingSchedule}
        redirectTo={`/queue/appeals/${props.match.params.appealId}`}
      >
        {params.action === 'reschedule' ? (
          <CaseDetailsLoadingScreen
            {...this.propsForQueueLoadingScreen()}
            preventReset
            appealId={props.match.params.appealId}
          >
            <ScheduleVeteran
              userCanCollectVideoCentralEmails={
                this.props.featureToggles.collect_video_and_central_emails
              }
              userCanViewTimeSlots={
                this.props.featureToggles.enable_hearing_time_slots
              }
              params={params}
              userId={this.props.userId}
              {...props.match.params}
            />
          </CaseDetailsLoadingScreen>
        ) : (
          <ScheduleVeteran
            userCanCollectVideoCentralEmails={
              this.props.featureToggles.collect_video_and_central_emails
            }
            userCanViewTimeSlots={
              this.props.featureToggles.enable_hearing_time_slots
            }
            params={params}
            userId={this.props.userId}
            {...props.match.params}
          />
        )}
      </PrivateRoute>
    );
  };

  routedAssignHearingModal = (props) => (
    <AssignHearingModal userId={this.props.userId} {...props.match.params} />
  );

  routedPostponeHearingModal = (props) => (
    <PostponeHearingModal
      userCanScheduleVirtualHearings={
        this.props.featureToggles.schedule_veteran_virtual_hearing
      }
      userId={this.props.userId}
      {...props.match.params}
    />
  );

  routedHearingScheduledInError = (props) => (
    <HearingScheduledInErrorModal
      userId={this.props.userId}
      {...props.match.params}
    />
  );

  routedChangeTaskTypeModal = (props) => (
    <ChangeTaskTypeModal {...props.match.params} />
  );

  routedChangeHearingRequestTypeToVirtual = (props) => (
    <HearingTypeConversionContainer type="Virtual" {...props.match.params} />
  );

  routedChangeHearingRequestTypeModal = (props) => (
    <HearingTypeConversionModal
      hearingType={props.hearingType}
      {...props.match.params}
    />
  );

  routedSetOvertimeStatusModal = (props) => (
    <SetOvertimeStatusModal {...props.match.params} />
  );

  routedChangeHearingDisposition = (props) => (
    <ChangeHearingDispositionModal {...props.match.params} />
  );

  routedCreateChangeHearingDispositionTask = (props) => (
    <CreateChangeHearingDispositionTaskModal {...props.match.params} />
  );

  routedSendColocatedTaskModal = (props) => {
    return (
      <CompleteTaskModal
        modalType="send_colocated_task"
        {...props.match.params}
      />
    );
  };

  routedBulkAssignTaskModal = (props) => {
    const { match } = props;
    const pageRoute = match.url.replace('modal/bulk_assign_tasks', '');

    return (
      <BulkAssignModal
        {...props}
        onCancel={() => props.history.push(pageRoute)}
      />
    );
  };

  routedOrganization = (props) => {
    const {
      match: { url },
    } = props;

    return (
      <OrganizationQueueLoadingScreen urlToLoad={`${url}/tasks`}>
        <OrganizationQueue {...this.props} />
      </OrganizationQueueLoadingScreen>
    );
  };

  routedOrganizationUsers = (props) => (
    <OrganizationUsers {...props.match.params} />
  );

  routedTeamManagement = (props) => <TeamManagement {...props.match.params} />;

  routedUserManagement = (props) => <UserManagement {...props.match.params} />;

  routedAddJudgeTeam = (props) => <AddJudgeTeamModal {...props.match.params} />;

  routedAddDvcTeam = (props) => <AddDvcTeamModal {...props.match.params} />;

  routedAddVsoModal = (props) => <AddVsoModal {...props.match.params} />;

  routedAddPrivateBarModal = (props) => (
    <AddPrivateBarModal {...props.match.params} />
  );

  routedLookupParticipantIdModal = (props) => (
    <LookupParticipantIdModal {...props.match.params} />
  );

  routedPostponeHearingTaskModal = (props) => (
    <PostponeHearingTaskModal {...props.match.params} />
  );

  routedStartHoldModal = (props) => <StartHoldModal {...props.match.params} />;

  routedEndHoldModal = (props) => <EndHoldModal {...props.match.params} />;

  routedCavcExtensionRequest = (props) => (
    <CavcReviewExtensionRequestModal
      {...props.match.params}
      closeModal={() => props.history.goBack()}
    />
  );

  routedCavcRemandReceived = (props) => (
    <AddCavcDatesModal {...props.match.params} />
  );

  routedEditAppellantInformation = (props) => (
    <EditAppellantInformation
      appealId={props.match.params.appealId}
      {...props.match.params}
    />
  )

  routedEditPOAInformation = (props) => (
    <EditPOAInformation
      appealId={props.match.params.appealId}
      {...props.match.params}
    />
  );

  routedCamoDocumentsReadyForBvaIntake = (props) => (
    <CompleteTaskModal modalType="vha_documents_ready_for_bva_intake_for_review" {...props.match.params} />
  );

  routedCamoReturnToBoardIntake = (props) => (
    <CompleteTaskModal modalType="vha_return_to_board_intake" {...props.match.params} />
  );

  routedEMOReturnToBoardIntake = (props) => (
    <CompleteTaskModal modalType="emo_return_to_board_intake" {...props.match.params} />
  );

  routedVhaCaregiverSupportReturnToBoardIntake = (props) => (
    <CompleteTaskModal modalType="vha_caregiver_support_return_to_board_intake" {...props.match.params} />
  );

  routedCompleteHearingPostponementRequest = (props) => (
    <CompleteHearingPostponementRequestModal {...props.match.params} />
  );

  queueName = () =>
    this.props.userRole === USER_ROLE_TYPES.attorney ?
      'Your Queue' :
      'Review Cases';

  propsForQueueLoadingScreen = () => {
    const { userId, userCssId, userRole, userIsCamoEmployee } = this.props;

    return {
      userId,
      userCssId,
      userRole,
      userIsCamoEmployee
    };
  };

  render = () => (
    <NavigationBar
      wideApp
      defaultUrl={
        this.props.caseSearchHomePage || this.props.hasCaseDetailsRole ?
          '/search' :
          '/queue'
      }
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      applicationUrls={this.props.applicationUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT,
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
              title="Search Cases | Caseflow"
              render={this.routedSearchResults}
            />
            <PageRoute
              exact
              path="/queue"
              title={`${this.queueName()}  | Caseflow`}
              render={this.routedQueueList}
            />
            <PageRoute
              exact
              path="/queue/:userId"
              title={`${this.queueName()}  | Caseflow`}
              render={this.routedQueueList}
            />
            <PageRoute
              exact
              path="/queue/:userId/review"
              title={`${PAGE_TITLES.REVIEW_CASES} | Caseflow`}
              render={this.routedTeamQueueList('review')}
            />
            <PageRoute
              path="/queue/:userId/assign"
              title={`${PAGE_TITLES.UNASSIGNED_CASES} | Caseflow`}
              render={this.routedTeamQueueList('assign')}
            />

            <PageRoute
              exact
              path="/queue/appeals/:appealId/notifications"
              title="Notifications | Caseflow"
              render={this.routedNotificationsWithLoadingScreen}
            />

            <PageRoute
              exact
              path="/queue/appeals/:appealId"
              title={`${PAGE_TITLES.CASE_DETAILS} | Caseflow`}
              render={this.routedQueueDetailWithLoadingScreen}
            />
            <PageRoute
              path={[
                '/queue/appeals/:appealId/tasks/:taskId/modal/:modalType',
                '/queue/appeals/:appealId/modal/:modalType',
              ]}
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
              title={(props) =>
                `${PAGE_TITLES.DRAFT_DECISION} | ${StringUtil.titleCase(
                  props.match.params.action
                )} Issue`
              }
              render={this.routedAddEditIssue}
            />
            <PageRoute
              exact
              path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/remands"
              title={`${PAGE_TITLES.DRAFT_DECISION} | ${PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()]
                }`}
              render={this.routedSetIssueRemandReasons}
            />
            <PageRoute
              exact
              path={[
                '/queue/appeals/:appealId/tasks/:taskId',
                ':checkoutFlow(draft_decision|dispatch_decision)/dispositions',
              ].join('/')}
              title={`${PAGE_TITLES.DRAFT_DECISION} | ${PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()]
                }`}
              render={this.routedSelectDispositions}
            />
            <PageRoute
              exact
              path={[
                '/queue/appeals/:appealId/tasks/:taskId/',
                ':checkoutFlow(draft_decision|dispatch_decision)/special_issues',
              ].join('')}
              title={`${PAGE_TITLES.DRAFT_DECISION} | ${COPY.SPECIAL_ISSUES_PAGE_TITLE}`}
              render={this.routedSelectSpecialIssues}
            />
            <PageRoute
              exact
              path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(dispatch_decision|omo_request)/evaluate"
              title={`${PAGE_TITLES.EVALUATE_DECISION} | Caseflow`}
              render={this.routedEvaluateDecision}
            />
            <PageRoute
              exact
              path="/queue/appeals/:appealId/tasks/:taskId/colocated_task"
              title={`${PAGE_TITLES.ADD_COLOCATED_TASK} | Caseflow`}
              render={this.routedAddColocatedTask}
            />
            <Route
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.BLOCKED_SPECIAL_CASE_MOVEMENT.value
                }`}
              render={this.routedBlockedCaseMovement}
            />

            <PageRoute
              exact
              path="/queue/appeals/:appealId/add_cavc_remand"
              title={`${PAGE_TITLES.ADD_CAVC_REMAND} | Caseflow`}
              render={this.routedAddCavcRemand}
            />
            <PageRoute
              exact
              path="/queue/appeals/:appealId/cavc_dashboard"
              title="CAVC Dashboard | Caseflow"
              render={this.routedCavcDashboard}
            />
            <PageRoute
              exact
              path="/organizations/:organization/users"
              title={`${PAGE_TITLES.ORGANIZATION_USERS} | Caseflow`}
              render={this.routedOrganizationUsers}
            />
            <PageRoute
              path="/organizations/:organization"
              title={`${PAGE_TITLES.ORGANIZATION_QUEUE} | Caseflow`}
              render={this.routedOrganization}
            />

            <PageRoute
              exact
              path="/queue/appeals/:appealId/edit_appellant_information"
              title={`${PAGE_TITLES.EDIT_APPELLANT_INFORMATION} | Caseflow`}
              render={this.routedEditAppellantInformation}
            />

            <PageRoute
              exact
              path="/queue/appeals/:appealId/edit_poa_information"
              title={`${PAGE_TITLES.EDIT_POA_INFORMATION} | Caseflow`}
              render={this.routedEditPOAInformation}
            />

            <PageRoute
              path="/team_management"
              title={`${PAGE_TITLES.TEAM_MANAGEMENT} | Caseflow`}
              render={this.routedTeamManagement}
            />
            <PageRoute
              path="/user_management"
              title={`${PAGE_TITLES.USER_MANAGEMENT} | Caseflow`}
              render={this.routedUserManagement}
            />

            {motionToVacateRoutes.page}

            {docketSwitchRoutes.page}

            {substituteAppellantRoutes.page}

            {editCavcRemandRoutes.page}
          </Switch>

          {/* Modal routes are in their own Switch so they will display above the base routes */}
          <Switch>
            <Route
              path="/queue/appeals/:appealId/modal/advanced_on_docket_motion"
              render={this.routedAdvancedOnDocketMotion}
            />
            <Route
              path="/queue/appeals/:appealId/modal/set_overtime_status"
              render={this.routedSetOvertimeStatusModal}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_ATTORNEY.value
                }`}
              render={this.routedAssignToAttorney}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_HEARING_ADMIN_MEMBER.value
                }`}
              render={this.routedReassignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_PERSON.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.value
                }`}
              render={this.routedAssignToSingleTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.SEND_TO_TRANSLATION_BLOCKING_DISTRIBUTION.value
                }`}
              render={this.routedAssignToSingleTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.SEND_TO_TRANSCRIPTION_BLOCKING_DISTRIBUTION.value
                }`}
              render={this.routedAssignToSingleTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                TASK_ACTIONS.SEND_IHP_TO_COLOCATED_BLOCKING_DISTRIBUTION.value
                }`}
              render={this.routedAssignToSingleTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SEND_TO_HEARINGS_BLOCKING_DISTRIBUTION.value
                }`}
              render={this.routedAssignToSingleTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CLARIFY_POA_BLOCKING_CAVC.value
                }`}
              render={this.routedAssignToSingleTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.value
                }`}
              render={this.routedPostponeHearingTaskModal}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_TEAM.value
                }`}
              render={this.routedAssignToTeam}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.DOCKET_APPEAL.value
                }`}
              render={this.routedDocketAppeal}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAMO.value
                }`}
              render={this.routedBvaIntakeReturnToOrg}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.BVA_INTAKE_RETURN_TO_EMO.value
                }`}
              render={this.routedBvaIntakeReturnToOrg}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.BVA_INTAKE_RETURN_TO_CAREGIVER.value
                }`}
              render={this.routedBvaIntakeReturnToOrg}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.VHA_ASSIGN_TO_PROGRAM_OFFICE.value
                }`}
              render={this.routedAssignToVhaProgramOffice}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.VHA_ASSIGN_TO_REGIONAL_OFFICE.value
                }`}
              render={this.routedAssignToVhaRegionalOffice}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.EMO_ASSIGN_TO_RPO.value
                }`}
              render={this.routedAssignToEducationRpo}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.VHA_PROGRAM_OFFICE_RETURN_TO_CAMO.value
                }`}
              render={this.routedReturnToCamo}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE.value
                }`}
              render={this.routedReturnToProgramOffice}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.EDUCATION_RPO_RETURN_TO_EMO.value
                }`}
              render={this.routedRpoReturnToEmo}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.VHA_MARK_TASK_IN_PROGRESS.value
                }`}
              render={this.routedMarkTaskInProgressModal}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CREATE_MAIL_TASK.value
                }`}
              render={this.routedCreateMailTask}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.REASSIGN_TO_JUDGE.value
                }`}
              render={this.routedReassignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.REASSIGN_TO_PERSON.value
                }`}
              render={this.routedReassignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.QR_RETURN_TO_JUDGE.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_QR_RETURN_TO_ATTORNEY.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.DISPATCH_RETURN_TO_JUDGE.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_DISPATCH_RETURN_TO_ATTORNEY.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CHANGE_HEARING_DISPOSITION.value
                }`}
              render={this.routedChangeHearingDisposition}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.value
                }`}
              render={this.routedCreateChangeHearingDispositionTask}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.PLACE_TIMED_HOLD.value
                }`}
              render={this.routedStartHoldModal}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.END_TIMED_HOLD.value
                }`}
              render={this.routedEndHoldModal}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SPECIAL_CASE_MOVEMENT.value
                }`}
              render={this.routedAssignToUser}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CAVC_EXTENSION_REQUEST.value
                }`}
              render={this.routedCavcExtensionRequest}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CAVC_REMAND_RECEIVED_MDR.value
                }`}
              render={this.routedCavcRemandReceived}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CAVC_REMAND_RECEIVED_VLJ.value
                }`}
              render={this.routedCavcRemandReceived}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.VHA_DOCUMENTS_READY_FOR_BVA_INTAKE_REVIEW.value
                }`}
              render={this.routedCamoDocumentsReadyForBvaIntake}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.VHA_RETURN_TO_BOARD_INTAKE.value
                }`}
              render={this.routedCamoReturnToBoardIntake}
            />
            <Route
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.EMO_RETURN_TO_BOARD_INTAKE.value
                }`}
              render={this.routedEMOReturnToBoardIntake}
            />

            <PageRoute
              exact
              path="/queue/appeals/:appealId/tasks/:taskId/place_hold"
              title="Place Hold | Caseflow"
              render={this.routedColocatedPlaceHold}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.MARK_TASK_AS_COMPLETE_CONTESTED_CLAIM.value
                }`}
              title="Mark Task Complete | Caseflow"
              render={this.routedCompleteTaskContestedClaimModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.MARK_FINAL_NOTIFICATION_LETTER_TASK_COMPLETE.value
                }`}
              title="Mark Task Complete | Caseflow"
              render={this.routedCompleteTaskContestedClaimModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.MARK_COMPLETE.value
                }`}
              title={`${PAGE_TITLES.MARK_TASK_COMPLETE} | Caseflow`}
              render={this.routedCompleteTaskModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL.value
                }`}
              title="Letter Task | Caseflow"
              render={this.routedProceedFinalNotificationLetterInitialModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING.value
                }`}
              title="Letter Task | Caseflow"
              render={this.routedProceedFinalNotificationLetterPostHoldingModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.RESEND_FINAL_NOTIFICATION_LETTER.value
                }`}
              title="Letter Task | Caseflow"
              render={this.routedResendFinalNotificationLetterModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING.value
                }`}
              title="Resend Letter Task | Caseflow"
              render={this.routedResendInitialNotificationLetterPostHoldingModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.RESEND_INITIAL_NOTIFICATION_LETTER_FINAL.value
                }`}
              title="Resend Letter Task | Caseflow"
              render={this.routedResendInitialNotificationLetterFinalModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.VHA_PO_SEND_TO_CAMO_FOR_REVIEW.value
                }`}
              title={`${PAGE_TITLES.READY_FOR_REVIEW} | Caseflow`}
              render={this.routedVhaCompleteTaskModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.EMO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.value
                }`}
              title={`${PAGE_TITLES.READY_FOR_REVIEW} | Caseflow`}
              render={this.routedEmoSendToBoardIntakeForReviewModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW.value
                }`}
              title={`${PAGE_TITLES.READY_FOR_REVIEW} | Caseflow`}
              render={this.routedVhaCaregiverSupportSendToBoardIntakeForReviewModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.EDUCATION_RPO_SEND_TO_BOARD_INTAKE_FOR_REVIEW.value
                }`}
              title={`${PAGE_TITLES.READY_FOR_REVIEW} | Caseflow`}
              render={this.routedRpoSendToBoardIntakeForReviewModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${
                  TASK_ACTIONS.VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE.value
                }`}
              title={`${PAGE_TITLES.RETURN_TO_BOARD_INTAKE} | Caseflow`}
              render={this.routedVhaCaregiverSupportReturnToBoardIntake}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.COMPLETE_AND_POSTPONE.value}`}
              title={`${PAGE_TITLES.COMPLETE_HEARING_POSTPONEMENT_REQUEST} | Caseflow`}
              render={this.routedCompleteHearingPostponementRequest}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.value
                }`}
              title={`${PAGE_TITLES.ASSIGN_TO_PULAC_CERULLO} | Caseflow`}
              render={this.routedAssignToPulacCerullo}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_CHECKOUT_PULAC_CERULLO_REMINDER.value
                }`}
              title={`${PAGE_TITLES.ASSIGN_TO_PULAC_CERULLO} | Caseflow`}
              render={this.routedPulacCerulloReminder}
            />
            <PageRoute
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.
                CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE.value
                }`}
              title={`${PAGE_TITLES.CANCEL_AND_ASSIGN_TO_RO} | Caseflow`}
              render={this.routedUpdateTaskAndAssignRegionalOfficeModal(
                TASK_STATUSES.cancelled
              )}
            />
            <PageRoute
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SEND_TO_SCHEDULE_VETERAN_LIST.value
                }`}
              title={`${PAGE_TITLES.SEND_TO_SCHEDULE_VETERAN_LIST} | Caseflow`}
              render={this.routedUpdateTaskAndAssignRegionalOfficeModal(
                TASK_STATUSES.completed
              )}
            />
            <PageRoute
              exact
              path={
                '/queue/appeals/:appealId/tasks/:taskId/' +
                `(${TASK_ACTIONS.WITHDRAW_HEARING.value}|${TASK_ACTIONS.CANCEL_TASK.value
                })`
              }
              title={`${PAGE_TITLES.CANCEL_TASK} | Caseflow`}
              render={this.routedCancelTaskModal}
            />
            <PageRoute
              exact
              path={
                `/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_FINAL_LETTER_TASK.value
                }`}
              title="Cancel Task"
              render={this.routedCancelLetterTaskModal}
            />
            <PageRoute
              exact
              path={
                `/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_INITIAL_LETTER_TASK.value
                }`}
              title="Cancel Task"
              render={this.routedCancelLetterTaskModal}
            />
            <PageRoute
              exact
              path={
                `/queue/appeals/:appealId/tasks/:taskId/${
                    TASK_ACTIONS.CANCEL_CONTESTED_CLAIM_POST_INITIAL_LETTER_TASK.value
                }`}
              title="Cancel Task"
              render={this.routedCancelLetterTaskModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SCHEDULE_VETERAN_V2_PAGE.value
                }`}
              title={`${PAGE_TITLES.ASSIGN_HEARING} | Caseflow`}
              render={this.routedScheduleVeteran}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SCHEDULE_VETERAN.value
                }`}
              title={`${PAGE_TITLES.ASSIGN_HEARING} | Caseflow`}
              render={this.routedAssignHearingModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.REMOVE_HEARING_SCHEDULED_IN_ERROR.value
                }`}
              title={`${PAGE_TITLES.REMOVE_HEARING_TO_CORRECT_ERROR} | Caseflow`}
              render={this.routedHearingScheduledInError}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.POSTPONE_HEARING.value
                }`}
              title={`${PAGE_TITLES.POSTPONE_HEARING} | Caseflow`}
              render={this.routedPostponeHearingModal}
            />
            <PageRoute
              exact
              path="/queue/appeals/:appealId/tasks/:taskId/modal/send_colocated_task"
              title={`${PAGE_TITLES.MARK_TASK_COMPLETE} | Caseflow`}
              render={this.routedSendColocatedTaskModal}
            />
            <PageRoute
              exact
              path="/queue/appeals/:appealId/tasks/:taskId/modal/change_task_type"
              title={`${PAGE_TITLES.CHANGE_TASK_TYPE} | Caseflow`}
              render={this.routedChangeTaskTypeModal}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIRTUAL.value
                }`}
              title={`${PAGE_TITLES.CONVERT_HEARING_TO_VIRTUAL} | Caseflow`}
              render={this.routedChangeHearingRequestTypeToVirtual}
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_VIDEO.value
                }`}
              title={`${PAGE_TITLES.CONVERT_HEARING_TO_VIDEO} | Caseflow`}
              render={(props) =>
                this.routedChangeHearingRequestTypeModal({
                  ...props,
                  hearingType: 'Video',
                })
              }
            />
            <PageRoute
              exact
              path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CHANGE_HEARING_REQUEST_TYPE_TO_CENTRAL.value
                }`}
              title={`${PAGE_TITLES.CONVERT_HEARING_TO_CENTRAL} | Caseflow`}
              render={(props) =>
                this.routedChangeHearingRequestTypeModal({
                  ...props,
                  hearingType: 'Central',
                })
              }
            />

            <Route
              path="/organizations/:organization/modal/bulk_assign_tasks"
              render={this.routedBulkAssignTaskModal}
            />

            <Route
              path="/team_management/add_judge_team"
              render={this.routedAddJudgeTeam}
            />
            <Route
              path="/team_management/add_dvc_team"
              render={this.routedAddDvcTeam}
            />
            <Route
              path="/team_management/add_vso"
              render={this.routedAddVsoModal}
            />
            <Route
              path="/team_management/add_private_bar"
              render={this.routedAddPrivateBarModal}
            />
            <Route
              path="/team_management/lookup_participant_id"
              render={this.routedLookupParticipantIdModal}
            />

            {motionToVacateRoutes.modal}
          </Switch>
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName=""
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate}
      />
    </NavigationBar>
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
  setCanViewOvertimeStatus: PropTypes.func,
  setCanEditNodDate: PropTypes.func,
  setUserIsCobAdmin: PropTypes.func,
  setCanEditCavcRemands: PropTypes.func,
  setCanEditCavcDashboards: PropTypes.func,
  setCanViewCavcDashboards: PropTypes.func,
  canEditAod: PropTypes.bool,
  setFeatureToggles: PropTypes.func,
  featureToggles: PropTypes.object,
  setUserRole: PropTypes.func,
  setUserCssId: PropTypes.func,
  setUserId: PropTypes.func,
  setOrganizations: PropTypes.func,
  organizations: PropTypes.array,
  setUserIsVsoEmployee: PropTypes.func,
  userIsVsoEmployee: PropTypes.bool,
  setUserIsCamoEmployee: PropTypes.func,
  userIsCamoEmployee: PropTypes.bool,
  setFeedbackUrl: PropTypes.func,
  hasCaseDetailsRole: PropTypes.bool,
  caseSearchHomePage: PropTypes.bool,
  applicationUrls: PropTypes.array,
  flash: PropTypes.array,
  reviewActionType: PropTypes.string,
  userCanEditUnrecognizedPOA: PropTypes.bool,
  userCanViewHearingSchedule: PropTypes.bool,
  userCanViewOvertimeStatus: PropTypes.bool,
  userCanViewEditNodDate: PropTypes.bool,
  userCanAssignHearingSchedule: PropTypes.bool,
  canEditCavcRemands: PropTypes.bool,
  canEditCavcDashboards: PropTypes.bool,
  canViewCavcDashboards: PropTypes.bool,
  userIsCobAdmin: PropTypes.bool,
};

const mapStateToProps = (state) => ({
  reviewActionType: state.queue.stagedChanges.taskDecision.type,
});

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      setCanEditAod,
      setCanEditNodDate,
      setUserIsCobAdmin,
      setCanEditCavcRemands,
      setCanEditCavcDashboards,
      setCanViewCavcDashboards,
      setCanViewOvertimeStatus,
      setFeatureToggles,
      setUserId,
      setUserRole,
      setUserCssId,
      setUserIsVsoEmployee,
      setUserIsCamoEmployee,
      setFeedbackUrl,
      setOrganizations,
    },
    dispatch
  );

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(QueueApp);
