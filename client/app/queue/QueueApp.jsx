// @flow
import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { BrowserRouter, Switch } from 'react-router-dom';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

import {
  setFeatureToggles,
  setUserRole,
  setUserCssId
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

import CaseListView from './CaseListView';
import CaseSearchSheet from './CaseSearchSheet';
import CaseDetailsView from './CaseDetailsView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';
import SearchBar from './SearchBar';
import BeaamAppealListView from './BeaamAppealListView';
import OrganizationQueue from './OrganizationQueue';

import { LOGO_COLORS } from '../constants/AppConstants';
import { PAGE_TITLES, USER_ROLES } from './constants';
import DECISION_TYPES from '../../constants/APPEAL_DECISION_TYPES.json';
import type { State } from './types/state';

const appStyling = css({ paddingTop: '3rem' });

type Props = {|
  userDisplayName: string,
  feedbackUrl: string,
  userId: number,
  userRole: string,
  userCssId: string,
  dropdownUrls: Array<string>,
  buildDate?: string,
  reviewActionType: string,
  userCanAccessQueue?: boolean,
  featureToggles: Object,
  // Action creators
  setFeatureToggles: typeof setFeatureToggles,
  setUserRole: typeof setUserRole,
  setUserCssId: typeof setUserCssId
|};

class QueueApp extends React.PureComponent<Props> {
  componentDidMount = () => {
    this.props.setFeatureToggles(this.props.featureToggles);
    this.props.setUserRole(this.props.userRole);
    this.props.setUserCssId(this.props.userCssId);
  }

  routedSearchResults = (props) => <React.Fragment>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    <CaseListView caseflowVeteranId={props.match.params.caseflowVeteranId} />
  </React.Fragment>;

  viewForUserRole = () => {
    const { userRole } = this.props;

    if (userRole === USER_ROLES.ATTORNEY) {
      return <AttorneyTaskListView {...this.props} />;
    } else if (userRole === USER_ROLES.JUDGE) {
      return <JudgeReviewTaskListView {...this.props} />;
    } else if (userRole === USER_ROLES.COLOCATED) {
      return <ColocatedTaskListView userId={this.props.userId} />;
    }
  }

  routedQueueList = () => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    {this.viewForUserRole()}
  </QueueLoadingScreen>;

  routedBeaamList = () => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()} urlToLoad="/beaam_appeals">
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    <BeaamAppealListView {...this.props} />
  </QueueLoadingScreen>;

  routedJudgeQueueList = (taskType) => ({ match }) => <QueueLoadingScreen {...this.propsForQueueLoadingScreen()}>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    {taskType === 'Assign' ?
      <JudgeAssignTaskListView {...this.props} match={match} /> :
      <JudgeReviewTaskListView {...this.props} />}
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <CaseDetailsLoadingScreen
    {...this.propsForQueueLoadingScreen()}
    appealId={props.match.params.appealId}>
    <CaseDetailsView appealId={props.match.params.appealId} />
  </CaseDetailsLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    appealId={props.match.params.appealId}
    nextStep="/queue" />;

  routedSelectDispositions = (props) => <SelectDispositionsView
    prevStep={`/queue/appeals/${props.match.params.appealId}`}
    appealId={props.match.params.appealId} />;

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/queue/appeals/${props.match.params.appealId}/dispositions`}
    prevStep={`/queue/appeals/${props.match.params.appealId}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView
    prevStep={`/queue/appeals/${props.match.params.appealId}/dispositions`}
    {...props.match.params} />;

  routedEvaluateDecision = (props) => <EvaluateDecisionView nextStep="/queue" {...props.match.params} />;

  routedAddColocatedTask = (props) => <AddColocatedTaskView nextStep="/queue" {...props.match.params} />;

  routedOrganization = (props) => <QueueLoadingScreen
    {...this.propsForQueueLoadingScreen()}
    urlToLoad={`${props.location.pathname}/tasks`}>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    <OrganizationQueue {...this.props} />
  </QueueLoadingScreen>

  queueName = () => this.props.userRole === USER_ROLES.ATTORNEY ? 'Your Queue' : 'Review Cases';

  propsForQueueLoadingScreen = () => {
    const {
      userId,
      userCssId,
      userRole,
      userCanAccessQueue
    } = this.props;

    return {
      userId,
      userCssId,
      userRole,
      userCanAccessQueue
    };
  }

  render = () => <BrowserRouter>
    <NavigationBar
      wideApp
      defaultUrl={this.props.userCanAccessQueue ? '/queue' : '/'}
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT
      }}
      appName="">
      <AppFrame wideApp>
        <ScrollToTop />
        <div className="cf-wide-app" {...appStyling}>
          <PageRoute
            exact
            path="/"
            title="Caseflow"
            component={CaseSearchSheet} />
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
            render={this.routedJudgeQueueList('Review')} />
          <PageRoute
            path="/queue/:userId/assign"
            title="Unassigned Cases | Caseflow"
            render={this.routedJudgeQueueList('Assign')} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId"
            title="Case Details | Caseflow"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/submit"
            title={() => {
              let reviewActionType = '';

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
            path="/queue/appeals/:appealId/dispositions/:action(add|edit)/:issueId?"
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/remands"
            title={`Draft Decision | ${PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/dispositions"
            title={`Draft Decision | ${PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSelectDispositions} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/evaluate"
            title="Evaluate Decision | Caseflow"
            render={this.routedEvaluateDecision} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/colocated_task"
            title="Add Colocated Task | Caseflow"
            render={this.routedAddColocatedTask} />
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
  setUserCssId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueApp);
