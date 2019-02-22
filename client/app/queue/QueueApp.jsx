/* eslint-disable max-lines */
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
import EvaluateDecisionView from './EvaluateDecisionView';
import AddColocatedTaskView from './AddColocatedTaskView';
import ColocatedPlaceHoldView from './ColocatedPlaceHoldView';
import CompleteTaskModal from './components/CompleteTaskModal';
import CancelTaskModal from './components/CancelTaskModal';
import AssignHearingModal from './components/AssignHearingModal';
import AdvancedOnDocketMotionView from './AdvancedOnDocketMotionView';
import AssignToAttorneyModalView from './AssignToAttorneyModalView';
import AssignToView from './AssignToView';
import CreateMailTaskDialog from './CreateMailTaskDialog';

import CaseListView from './CaseListView';
import CaseDetailsView from './CaseDetailsView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsContainer from './SelectDispositionsContainer';
import SelectSpecialIssuesView from './SelectSpecialIssuesView';
import SpecialIssueLoadingScreen from './SpecialIssueLoadingScreen';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';
import BeaamAppealListView from './BeaamAppealListView';
import OrganizationQueue from './OrganizationQueue';
import OrganizationUsers from './OrganizationUsers';
import OrganizationQueueLoadingScreen from './OrganizationQueueLoadingScreen';

import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_TITLES } from './constants';
import COPY from '../../COPY.json';
import TASK_ACTIONS from '../../constants/TASK_ACTIONS.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';

class QueueApp extends React.PureComponent {
  componentDidMount = () => {
    this.props.setCanEditAod(this.props.canEditAod);
    this.props.setFeatureToggles(this.props.featureToggles);
    this.props.setUserRole(this.props.userRole);
    this.props.setUserCssId(this.props.userCssId);
    this.props.setOrganizations(this.props.organizations);
    this.props.setUserIsVsoEmployee(this.props.userIsVsoEmployee);
    this.props.setFeedbackUrl(this.props.feedbackUrl);
  }

  routedSearchResults = (props) => <CaseListView caseflowVeteranId={props.match.params.caseflowVeteranId} />;

  viewForUserRole = () => {
    const { userRole } = this.props;

    if (userRole === USER_ROLE_TYPES.attorney) {
      return <AttorneyTaskListView />;
    } else if (userRole === USER_ROLE_TYPES.judge) {
      return <JudgeDecisionReviewTaskListView {...this.props} />;
    }

    return <ColocatedTaskListView />;
  }

  routedQueueList = () => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
    {this.viewForUserRole()}
  </QueueLoadingScreen>;

  routedBeaamList = () => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()} urlToLoad="/beaam_appeals">
    <BeaamAppealListView {...this.props} />
  </QueueLoadingScreen>;

  routedJudgeQueueList = (label) => ({ match }) => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
    {label === 'assign' ?
      <JudgeAssignTaskListView {...this.props} match={match} /> :
      <JudgeDecisionReviewTaskListView {...this.props} />}
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <CaseDetailsView appealId={props.match.params.appealId} />;

  routedQueueDetailWithLoadingScreen = (props) => <CaseDetailsLoadingScreen
    {...this.propsForQueueLoadingScreen()}
    appealId={props.match.params.appealId}>
    {this.routedQueueDetail(props)}
  </CaseDetailsLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    appealId={props.match.params.appealId}
    taskId={props.match.params.taskId}
    checkoutFlow={props.match.params.checkoutFlow}
    nextStep="/queue" />;

  routedSelectDispositions = (props) => <SelectDispositionsContainer
    appealId={props.match.params.appealId}
    taskId={props.match.params.taskId}
    checkoutFlow={props.match.params.checkoutFlow} />;

  routedSelectSpecialIssues = (props) => {
    const {
      appealId,
      checkoutFlow,
      taskId
    } = props.match.params;

    return <SpecialIssueLoadingScreen appealExternalId={appealId}>
      <SelectSpecialIssuesView
        appealId={appealId}
        taskId={taskId}
        prevStep={`/queue/appeals/${appealId}`}
        nextStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`} />
    </SpecialIssueLoadingScreen>;
  }

  routedAddEditIssue = (props) => {
    const {
      appealId,
      checkoutFlow,
      taskId
    } = props.match.params;

    return <AddEditIssueView
      nextStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`}
      prevStep={`/queue/appeals/${appealId}/tasks/${taskId}/${checkoutFlow}/dispositions`}
      {...props.match.params} />;
  }

  routedSetIssueRemandReasons = (props) => {
    const {
      appealId,
      checkoutFlow,
      taskId
    } = props.match.params;

    return <SelectRemandReasonsView
      prevStep={`/queue/appeals/${appealId}/tasks/${taskId}` +
        `/${checkoutFlow}/dispositions`}
      {...props.match.params} />;
  }

  routedEvaluateDecision = (props) => <EvaluateDecisionView nextStep="/queue" {...props.match.params} />;

  routedAddColocatedTask = (props) => <AddColocatedTaskView {...props.match.params} />;

  routedColocatedPlaceHold = (props) => <ColocatedPlaceHoldView nextStep="/queue" {...props.match.params} />;

  routedAdvancedOnDocketMotion = (props) => <AdvancedOnDocketMotionView {...props.match.params} />;

  routedAssignToAttorney = (props) => <AssignToAttorneyModalView userId={this.props.userId} {...props.match.params} />;

  routedAssignToSingleTeam = (props) => <AssignToView isTeamAssign assigneeAlreadySelected {...props.match.params} />;

  routedAssignToTeam = (props) => <AssignToView isTeamAssign {...props.match.params} />;

  routedCreateMailTask = (props) => <CreateMailTaskDialog {...props.match.params} />;

  routedAssignToUser = (props) => <AssignToView {...props.match.params} />;

  routedReassignToUser = (props) => <AssignToView isReassignAction {...props.match.params} />;

  routedCompleteTaskModal = (props) => <CompleteTaskModal modalType="mark_task_complete" {...props.match.params} />;

  routedCancelTaskModal = (props) => <CancelTaskModal {...props.match.params} />;

  routedAssignHearingModal = (props) => <AssignHearingModal userId={this.props.userId} {...props.match.params} />;

  routedSendColocatedTaskModal = (props) =>
    <CompleteTaskModal modalType="send_colocated_task" {...props.match.params} />;

  routedOrganization = (props) => <OrganizationQueueLoadingScreen
    urlToLoad={`${props.location.pathname}/tasks`}>
    <OrganizationQueue {...this.props} />
  </OrganizationQueueLoadingScreen>

  routedOrganizationUsers = (props) => <OrganizationUsers {...props.match.params} />;

  queueName = () => this.props.userRole === USER_ROLE_TYPES.attorney ? 'Your Queue' : 'Review Cases';

  propsForQueueLoadingScreen = () => {
    const {
      userId,
      userRole
    } = this.props;

    return {
      userId,
      userRole
    };
  }

  render = () => <BrowserRouter>
    <NavigationBar
      wideApp
      defaultUrl={this.props.caseSearchHomePage ? '/search' : '/queue'}
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      applicationUrls={this.props.applicationUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT
      }}
      rightNavElement={<CaseSearchLink />}
      appName="Queue">
      <AppFrame wideApp>
        <ScrollToTop />
        <div className="cf-wide-app">
          <PageRoute
            exact
            path="/search"
            title="Caseflow"
            render={this.routedSearchResults} />
          <PageRoute
            exact
            path="/cases/:caseflowVeteranId"
            title="Case Search | Caseflow"
            render={this.routedSearchResults} />
          <PageRoute
            exact
            path="/queue"
            title={`${this.queueName()}  | Caseflow`}
            render={this.routedQueueList} />
          <Switch>
            <PageRoute
              exact
              path="/queue/beaam"
              title="BEAAM Appeals"
              render={this.routedBeaamList} />
            <PageRoute
              exact
              path="/queue/:userId"
              title={`${this.queueName()}  | Caseflow`}
              render={this.routedQueueList} />
          </Switch>
          <PageRoute
            exact
            path="/queue/:userId/review"
            title="Review Cases | Caseflow"
            render={this.routedJudgeQueueList('review')} />
          <PageRoute
            path="/queue/:userId/assign"
            title="Unassigned Cases | Caseflow"
            render={this.routedJudgeQueueList('assign')} />
          <Route
            path="/queue/appeals/:appealId/modal/advanced_on_docket_motion"
            render={this.routedAdvancedOnDocketMotion} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_ATTORNEY.value}`}
            render={this.routedAssignToAttorney} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.JUDGE_RETURN_TO_ATTORNEY.value}`}
            render={this.routedAssignToUser} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_PERSON.value}`}
            render={this.routedAssignToUser} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_PRIVACY_TEAM.value}`}
            render={this.routedAssignToSingleTeam} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SEND_TO_TRANSLATION.value}`}
            render={this.routedAssignToSingleTeam} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.ASSIGN_TO_TEAM.value}`}
            render={this.routedAssignToTeam} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.CREATE_MAIL_TASK.value}`}
            render={this.routedCreateMailTask} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.REASSIGN_TO_PERSON.value}`}
            render={this.routedReassignToUser} />
          <Route
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.RETURN_TO_JUDGE.value}`}
            render={this.routedAssignToUser} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId"
            title="Case Details | Caseflow"
            render={this.routedQueueDetailWithLoadingScreen} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/modal/:modalType"
            title="Case Details | Caseflow"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path={'/queue/appeals/:appealId/tasks/:taskId/' +
              ':checkoutFlow(draft_decision|dispatch_decision|omo_request)/submit'}
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
            render={this.routedSubmitDecision} />
          <PageRoute
            exact
            path={'/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/' +
              'dispositions/:action(add|edit)/:issueId?'}
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/remands"
            title={`Draft Decision | ${PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/dispositions"
            title={`Draft Decision | ${PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSelectDispositions} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(draft_decision|dispatch_decision)/special_issues"
            title={`Draft Decision | ${COPY.SPECIAL_ISSUES_PAGE_TITLE}`}
            render={this.routedSelectSpecialIssues} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/:checkoutFlow(dispatch_decision|omo_request)/evaluate"
            title="Evaluate Decision | Caseflow"
            render={this.routedEvaluateDecision} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/colocated_task"
            title="Add Colocated Task | Caseflow"
            render={this.routedAddColocatedTask} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/place_hold"
            title="Place Hold | Caseflow"
            render={this.routedColocatedPlaceHold} />
          <PageRoute
            exact
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.MARK_COMPLETE.value}`}
            title="Mark Task Complete | Caseflow"
            render={this.routedCompleteTaskModal} />
          <PageRoute
            exact
            path={'/queue/appeals/:appealId/tasks/:taskId/' +
              `(${TASK_ACTIONS.WITHDRAW_HEARING.value}|${TASK_ACTIONS.CANCEL_TASK.value})`}
            title="Cancel task | Caseflow"
            render={this.routedCancelTaskModal} />
          <PageRoute
            exact
            path={`/queue/appeals/:appealId/tasks/:taskId/${TASK_ACTIONS.SCHEDULE_VETERAN.value}`}
            title="Assign Hearing | Caseflow"
            render={this.routedAssignHearingModal} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/tasks/:taskId/modal/send_colocated_task"
            title="Mark Task Complete | Caseflow"
            render={this.routedSendColocatedTaskModal} />
          <PageRoute
            exact
            path="/organizations/:organization"
            title="Organization Queue | Caseflow"
            render={this.routedOrganization} />
          <PageRoute
            exact
            path="/organizations/:organization/users"
            title="Organization Users | Caseflow"
            render={this.routedOrganizationUsers} />
        </div>
      </AppFrame>
      <Footer
        wideApp
        appName=""
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate} />
    </NavigationBar>
  </BrowserRouter>;
}

QueueApp.propTypes = {
  userDisplayName: PropTypes.string.isRequired,
  feedbackUrl: PropTypes.string.isRequired,
  userId: PropTypes.number.isRequired,
  userRole: PropTypes.string.isRequired,
  userCssId: PropTypes.string.isRequired,
  dropdownUrls: PropTypes.array,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => ({
  reviewActionType: state.queue.stagedChanges.taskDecision.type
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setCanEditAod,
  setFeatureToggles,
  setUserRole,
  setUserCssId,
  setUserIsVsoEmployee,
  setFeedbackUrl,
  setOrganizations
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueApp);
