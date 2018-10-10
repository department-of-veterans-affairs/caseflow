// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { Route, BrowserRouter, Switch } from 'react-router-dom';
import StringUtil from '../util/StringUtil';

import {
  setFeatureToggles,
  setUserRole,
  setUserCssId,
  setUserIsVsoEmployee,
  setFeedbackUrl
} from './uiReducer/uiActions';

import ScrollToTop from '../components/ScrollToTop';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import QueueLoadingScreen from './QueueLoadingScreen';
import CaseDetailsLoadingScreen from './CaseDetailsLoadingScreen';
import AttorneyTaskListView from './AttorneyTaskListView';
import ColocatedTaskListView from './ColocatedTaskListView';
import JudgeReviewTaskListView from './JudgeReviewTaskListView';
import JudgeAssignTaskListView from './JudgeAssignTaskListView';
import EvaluateDecisionView from './EvaluateDecisionView';
import AddColocatedTaskView from './AddColocatedTaskView';
import ColocatedPlaceHoldView from './ColocatedPlaceHoldView';
import MarkTaskCompleteView from './MarkTaskCompleteView';
import AdvancedOnDocketMotionView from './AdvancedOnDocketMotionView';
import AssignToAttorneyModalView from './AssignToAttorneyModalView';
import AssignToView from './AssignToView';

import TriggerModal from './TriggerModal';

import CaseListView from './CaseListView';
import CaseDetailsView from './CaseDetailsView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import SelectSpecialIssuesView from './SelectSpecialIssuesView';
import SpecialIssueLoadingScreen from './SpecialIssueLoadingScreen';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';
import BeaamAppealListView from './BeaamAppealListView';
import OrganizationQueue from './OrganizationQueue';
import OrganizationQueueLoadingScreen from './OrganizationQueueLoadingScreen';

import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_TITLES } from './constants';
import COPY from '../../COPY.json';
import USER_ROLE_TYPES from '../../constants/USER_ROLE_TYPES.json';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import type { State } from './types/state';

type Props = {|
  userDisplayName: string,
  feedbackUrl: string,
  userId: number,
  userRole: string,
  userCssId: string,
  dropdownUrls: Array<string>,
  buildDate?: string,
  reviewActionType: string,
  userIsVsoEmployee?: boolean,
  caseSearchHomePage?: boolean,
  featureToggles: Object,
  // Action creators
  setFeatureToggles: typeof setFeatureToggles,
  setUserRole: typeof setUserRole,
  setUserCssId: typeof setUserCssId,
  setUserIsVsoEmployee: typeof setUserIsVsoEmployee,
  setFeedbackUrl: typeof setFeedbackUrl
|};

class QueueApp extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.setFeatureToggles(this.props.featureToggles);
    this.props.setUserRole(this.props.userRole);
    this.props.setUserCssId(this.props.userCssId);
    this.props.setUserIsVsoEmployee(this.props.userIsVsoEmployee);
    this.props.setFeedbackUrl(this.props.feedbackUrl);
  }

  routedSearchResults = (props) => <CaseListView caseflowVeteranId={props.match.params.caseflowVeteranId} />;

  viewForUserRole = () => {
    const { userRole } = this.props;

    if (userRole === USER_ROLE_TYPES.attorney) {
      return <AttorneyTaskListView />;
    } else if (userRole === USER_ROLE_TYPES.judge) {
      return <JudgeReviewTaskListView {...this.props} />;
    }

    return <ColocatedTaskListView />;

  }

  routedQueueList = () => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
    {this.viewForUserRole()}
  </QueueLoadingScreen>;

  routedBeaamList = () => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()} urlToLoad="/beaam_appeals">
    <BeaamAppealListView {...this.props} />
  </QueueLoadingScreen>;

  routedJudgeQueueList = (action) => ({ match }) => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
    {action === 'assign' ?
      <JudgeAssignTaskListView {...this.props} match={match} /> :
      <JudgeReviewTaskListView {...this.props} />}
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <CaseDetailsView appealId={props.match.params.appealId} />;

  routedQueueDetailWithLoadingScreen = (props) => <CaseDetailsLoadingScreen
    {...this.propsForQueueLoadingScreen()}
    appealId={props.match.params.appealId}>
    {this.routedQueueDetail(props)}
  </CaseDetailsLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    appealId={props.match.params.appealId}
    checkoutFlow={props.match.params.checkoutFlow}
    nextStep="/queue" />;

  routedSelectDispositions = (props) => <SelectDispositionsView
    appealId={props.match.params.appealId}
    checkoutFlow={props.match.params.checkoutFlow} />;

  routedSelectSpecialIssues = (props) => <SpecialIssueLoadingScreen appealExternalId={props.match.params.appealId}>
    <SelectSpecialIssuesView
      appealId={props.match.params.appealId}
      prevStep={`/queue/appeals/${props.match.params.appealId}`}
      nextStep={`/queue/appeals/${props.match.params.appealId}/${props.match.params.checkoutFlow}/dispositions`} />
  </SpecialIssueLoadingScreen>;

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/queue/appeals/${props.match.params.appealId}/${props.match.params.checkoutFlow}/dispositions`}
    prevStep={`/queue/appeals/${props.match.params.appealId}/${props.match.params.checkoutFlow}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView
    prevStep={`/queue/appeals/${props.match.params.appealId}/${props.match.params.checkoutFlow}/dispositions`}
    {...props.match.params} />;

  routedEvaluateDecision = (props) => <EvaluateDecisionView nextStep="/queue" {...props.match.params} />;

  routedAddColocatedTask = (props) => <AddColocatedTaskView nextStep="/queue" {...props.match.params} />;

  routedColocatedPlaceHold = (props) => <ColocatedPlaceHoldView nextStep="/queue" {...props.match.params} />;

  routedAdvancedOnDocketMotion = (props) => <AdvancedOnDocketMotionView {...props.match.params} />;

  routedAssignToAttorney = (props) => <AssignToAttorneyModalView {...props.match.params} />;

  routedAssignToTeam = (props) => <AssignToView isTeamAssign {...props.match.params} />;

  routedAssignToUser = (props) => <AssignToView {...props.match.params} />;

  routedMarkTaskComplete = (props) => <MarkTaskCompleteView
    nextStep={`/queue/appeals/${props.match.params.appealId}`}
    {...props.match.params} />;

  triggerModal = (props) => <TriggerModal modal={props.match.params.modalType} />;

  routedOrganization = (props) => <OrganizationQueueLoadingScreen
    urlToLoad={`${props.location.pathname}/tasks`}>
    <OrganizationQueue {...this.props} />
  </OrganizationQueueLoadingScreen>

  queueName = () => this.props.userRole === USER_ROLE_TYPES.attorney ? 'Your Queue' : 'Review Cases';

  propsForQueueLoadingScreen = () => {
    const {
      userId,
      userCssId,
      userRole
    } = this.props;

    return {
      userId,
      userCssId,
      userRole
    };
  }

  render = () => <BrowserRouter>
    <NavigationBar
      wideApp
      defaultUrl={this.props.caseSearchHomePage ? '/search' : '/queue'}
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT
      }}
      appName="">
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
            path="/queue/appeals/:appealId/modal/assign_to_team"
            render={this.routedAssignToTeam} />
          <Route
            path="/queue/appeals/:appealId/modal/assign_to_person"
            render={this.routedAssignToUser} />
          <Route
            path="/queue/appeals/:appealId/modal/assign_to_attorney"
            render={this.routedAssignToAttorney} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId"
            title="Case Details | Caseflow"
            render={this.routedQueueDetailWithLoadingScreen} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/modal/:modalType"
            title="Case Details | Caseflow"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/:checkoutFlow(draft_decision|dispatch_decision|omo_request)/submit"
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
            path={'/queue/appeals/:appealId/:checkoutFlow(draft_decision|dispatch_decision)/' +
              'dispositions/:action(add|edit)/:issueId?'}
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/:checkoutFlow(draft_decision|dispatch_decision)/remands"
            title={`Draft Decision | ${PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/:checkoutFlow(draft_decision|dispatch_decision)/dispositions"
            title={`Draft Decision | ${PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSelectDispositions} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/:checkoutFlow(draft_decision|dispatch_decision)/special_issues"
            title={`Draft Decision | ${COPY.SPECIAL_ISSUES_PAGE_TITLE}`}
            render={this.routedSelectSpecialIssues} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/:checkoutFlow(dispatch_decision|omo_request)/evaluate"
            title="Evaluate Decision | Caseflow"
            render={this.routedEvaluateDecision} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/colocated_task"
            title="Add Colocated Task | Caseflow"
            render={this.routedAddColocatedTask} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/place_hold"
            title="Place Hold | Caseflow"
            render={this.routedColocatedPlaceHold} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/mark_task_complete"
            title="Mark Task Complete | Caseflow"
            render={this.routedMarkTaskComplete} />
          <PageRoute
            exact
            path="/queue/modal/:modalType"
            title="Caseflow"
            render={this.triggerModal} />
          <PageRoute
            exact
            path="/organizations/:organization"
            title="Organization Queue | Caseflow"
            render={this.routedOrganization} />
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

const mapStateToProps = (state: State) => ({
  reviewActionType: state.queue.stagedChanges.taskDecision.type
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setFeatureToggles,
  setUserRole,
  setUserCssId,
  setUserIsVsoEmployee,
  setFeedbackUrl
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueApp);
