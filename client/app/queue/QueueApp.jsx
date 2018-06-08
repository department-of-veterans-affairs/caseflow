import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { BrowserRouter, Switch } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

import { setFeatureToggles, setUserRole } from './uiReducer/uiActions';

import ScrollToTop from '../components/ScrollToTop';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import Breadcrumbs from './components/BreadcrumbManager';
import QueueLoadingScreen from './QueueLoadingScreen';
import AttorneyTaskListView from './AttorneyTaskListView';
import JudgeReviewTaskListView from './JudgeReviewTaskListView';
import JudgeAssignTaskListView from './JudgeAssignTaskListView';
import EvaluateDecisionView from './EvaluateDecisionView';

import CaseListView from './CaseListView';
import CaseSearchSheet from './CaseSearchSheet';
import QueueDetailView from './QueueDetailView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';
import SearchBar from './SearchBar';
import BeaamAppealListView from './BeaamAppealListView';

import { LOGO_COLORS } from '../constants/AppConstants';
import { DECISION_TYPES, PAGE_TITLES, USER_ROLES } from './constants';

const appStyling = css({ paddingTop: '3rem' });

class QueueApp extends React.PureComponent {
  componentDidMount = () => {
    this.props.setFeatureToggles(this.props.featureToggles);
    this.props.setUserRole(this.props.userRole);
  }

  routedSearchResults = (props) => <React.Fragment>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    <CaseListView caseflowVeteranId={props.match.params.caseflowVeteranId} />
  </React.Fragment>;

  routedQueueList = () => <QueueLoadingScreen {...this.props}>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    {this.props.userRole === USER_ROLES.ATTORNEY ?
      <AttorneyTaskListView {...this.props} /> :
      <JudgeReviewTaskListView {...this.props} />
    }
  </QueueLoadingScreen>;

  routedBeaamList = () => <QueueLoadingScreen {...this.props} urlToLoad="/beaam_appeals">
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    <BeaamAppealListView {...this.props} />
  </QueueLoadingScreen>;

  routedJudgeQueueList = (taskType) => ({ match }) => <QueueLoadingScreen {...this.props}>
    <SearchBar feedbackUrl={this.props.feedbackUrl} />
    {taskType === 'Assign' ?
      <JudgeAssignTaskListView {...this.props} match={match} /> :
      <JudgeReviewTaskListView {...this.props} />}
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props} vacolsId={props.match.params.vacolsId}>
    <Breadcrumbs />
    <QueueDetailView vacolsId={props.match.params.vacolsId} />
  </QueueLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    vacolsId={props.match.params.vacolsId}
    nextStep="/queue" />;

  routedSelectDispositions = (props) => <SelectDispositionsView vacolsId={props.match.params.vacolsId} />;

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/queue/appeals/${props.match.params.vacolsId}/dispositions`}
    prevStep={`/queue/appeals/${props.match.params.vacolsId}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView {...props.match.params} />;

  routedEvaluateDecision = (props) => <EvaluateDecisionView
    nextStep={`/queue/appeals/${props.match.params.appealId}/submit`}
    {...props.match.params} />;

  queueName = () => this.props.userRole === USER_ROLES.ATTORNEY ? 'Your Queue' : 'Review Cases';

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
            path="/queue/appeals/:vacolsId"
            title="Case Details | Caseflow"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path="/queue/appeals/:vacolsId/submit"
            title={() => {
              const reviewActionType = this.props.reviewActionType === DECISION_TYPES.OMO_REQUEST ?
                'OMO' : 'Draft Decision';

              return `Draft Decision | Submit ${reviewActionType}`;
            }}
            render={this.routedSubmitDecision} />
          <PageRoute
            exact
            path="/queue/appeals/:vacolsId/dispositions/:action(add|edit)/:issueId?"
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/remands"
            title={`Draft Decision | ${PAGE_TITLES.REMANDS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/queue/appeals/:vacolsId/dispositions"
            title={`Draft Decision | ${PAGE_TITLES.DISPOSITIONS[this.props.userRole.toUpperCase()]}`}
            render={this.routedSelectDispositions} />
          <PageRoute
            exact
            path="/queue/appeals/:appealId/evaluate"
            title="Evaluate Decision | Caseflow"
            render={this.routedEvaluateDecision} />
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
  ..._.pick(state.caseSelect, 'caseSelectCriteria.searchQuery'),
  ..._.pick(state.queue.loadedQueue, 'appeals'),
  reviewActionType: state.queue.stagedChanges.taskDecision.type,
  searchedAppeals: state.caseList.receivedAppeals
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setFeatureToggles,
  setUserRole
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(QueueApp);
