import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

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

import CaseListView from './CaseListView';
import CaseSearchSheet from './CaseSearchSheet';
import QueueDetailView from './QueueDetailView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';
import SearchBar from './SearchBar';

import { LOGO_COLORS } from '../constants/AppConstants';
import { DECISION_TYPES } from './constants';

const appStyling = css({ paddingTop: '3rem' });

class QueueApp extends React.PureComponent {
  routedSearchResults = (props) => <React.Fragment>
    <SearchBar
      feedbackUrl={this.props.feedbackUrl}
      shouldUseQueueCaseSearch={this.props.featureToggles.queue_case_search} />
    <CaseListView caseflowVeteranId={props.match.params.caseflowVeteranId} />
  </React.Fragment>;

  routedQueueList = (routerProps) => <QueueLoadingScreen {...this.props} {...routerProps}>
    <SearchBar
      feedbackUrl={this.props.feedbackUrl}
      shouldUseQueueCaseSearch={this.props.featureToggles.queue_case_search} />
    {this.props.userRole === 'Attorney' ?
      <AttorneyTaskListView {...this.props} /> :
      <JudgeReviewTaskListView {...this.props} />
    }
  </QueueLoadingScreen>;

  routedJudgeQueueList = (taskType) => ({ match }) => <QueueLoadingScreen {...this.props}>
    <SearchBar
      feedbackUrl={this.props.feedbackUrl}
      shouldUseQueueCaseSearch={this.props.featureToggles.queue_case_search} />
    {taskType === 'Assign' ?
      <JudgeAssignTaskListView {...this.props} match={match} /> :
      <JudgeReviewTaskListView {...this.props} />}
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props} vacolsId={props.match.params.vacolsId}>
    <Breadcrumbs />
    <QueueDetailView {...this.props}
      vacolsId={props.match.params.vacolsId} />
  </QueueLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    vacolsId={props.match.params.vacolsId}
    nextStep="/queue" />;

  routedSelectDispositions = (props) => {
    const { vacolsId } = props.match.params;

    return <SelectDispositionsView
      vacolsId={vacolsId}
      prevStep={`/queue/appeals/${vacolsId}`}
      nextStep={`/queue/appeals/${vacolsId}/submit`} />;
  };

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/queue/appeals/${props.match.params.vacolsId}/dispositions`}
    prevStep={`/queue/appeals/${props.match.params.vacolsId}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView
    nextStep={`/queue/appeals/${props.match.params.appealId}/submit`}
    {...props.match.params} />;

  queueName = () => this.props.userRole === 'Attorney' ? 'Your Queue' : 'Review Cases';

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
          <PageRoute
            exact
            path="/queue/:userId"
            title={`${this.queueName()}  | Caseflow`}
            render={this.routedQueueList} />
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
            title="Draft Decision | Select Issue Remand Reasons"
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/queue/appeals/:vacolsId/dispositions"
            title="Draft Decision | Select Dispositions"
            render={this.routedSelectDispositions} />
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

export default connect(mapStateToProps)(QueueApp);
