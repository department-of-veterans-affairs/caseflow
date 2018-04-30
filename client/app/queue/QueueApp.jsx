import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import AppFrame from '../components/AppFrame';
import Breadcrumbs from './components/BreadcrumbManager';
import QueueLoadingScreen from './QueueLoadingScreen';
import AttorneyTaskListView from './AttorneyTaskListView';
import JudgeReviewTaskListView from './JudgeReviewTaskListView';
import JudgeAssignTaskListView from './JudgeAssignTaskListView';

import CaseDetailView from './CaseDetailView';
import QueueDetailView from './QueueDetailView';
import SearchEnabledView from './SearchEnabledView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import AddEditIssueView from './AddEditIssueView';
import SelectRemandReasonsView from './SelectRemandReasonsView';

import { LOGO_COLORS } from '../constants/AppConstants';
import { DECISION_TYPES } from './constants';

const appStyling = css({ paddingTop: '3rem' });

class QueueApp extends React.PureComponent {
  routedQueueList = () => <QueueLoadingScreen {...this.props}>
    <SearchEnabledView
      feedbackUrl={this.props.feedbackUrl}
      shouldUseQueueCaseSearch={this.props.featureToggles.queue_case_search}>
      {this.props.userRole === 'Attorney' ?
        <AttorneyTaskListView {...this.props} /> :
        <JudgeReviewTaskListView {...this.props} />
      }
    </SearchEnabledView>
  </QueueLoadingScreen>;

  routedJudgeQueueList = (taskType) => () => <QueueLoadingScreen {...this.props}>
    <SearchEnabledView
      feedbackUrl={this.props.feedbackUrl}
      shouldUseQueueCaseSearch={this.props.featureToggles.queue_case_search}>
      {taskType === 'Assign' ?
        <JudgeAssignTaskListView {...this.props} /> :
        <JudgeReviewTaskListView {...this.props} />}
    </SearchEnabledView>
  </QueueLoadingScreen>;

  routedCaseDetail = (props) => <QueueLoadingScreen {...this.props}>
    <CaseDetailView vacolsId={props.match.params.vacolsId} />
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props}>
    <Breadcrumbs />
    <QueueDetailView
      vacolsId={props.match.params.vacolsId}
      featureToggles={this.props.featureToggles} />
  </QueueLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    vacolsId={props.match.params.vacolsId}
    nextStep="/queue" />;

  routedSelectDispositions = (props) => {
    const { vacolsId } = props.match.params;

    return <SelectDispositionsView
      vacolsId={vacolsId}
      prevStep={`/queue/tasks/${vacolsId}`}
      nextStep={`/queue/tasks/${vacolsId}/submit`} />;
  };

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/queue/tasks/${props.match.params.vacolsId}/dispositions`}
    prevStep={`/queue/tasks/${props.match.params.vacolsId}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView
    nextStep={`/queue/tasks/${props.match.params.appealId}/submit`}
    {...props.match.params} />;

  render = () => <BrowserRouter>
    <NavigationBar
      wideApp
      defaultUrl="/queue"
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT
      }}
      appName="">
      <AppFrame wideApp>
        <div className="cf-wide-app" {...appStyling}>
          <PageRoute
            exact
            path="/queue"
            title="Your Queue | Caseflow"
            render={this.routedQueueList} />
          <PageRoute
            exact
            path="/queue/:userId"
            title="Your Queue | Caseflow"
            render={this.routedQueueList} />
          <PageRoute
            exact
            path="/queue/:userId/review"
            title="Your Queue | Caseflow"
            render={this.routedJudgeQueueList('Review')} />
          <PageRoute
            exact
            path="/queue/:userId/assign"
            title="Your Queue | Caseflow"
            render={this.routedJudgeQueueList('Assign')} />
          <PageRoute
            exact
            path="/queue/tasks/:vacolsId"
            title="Draft Decision | Caseflow"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path="/queue/tasks/:vacolsId/submit"
            title={() => {
              const reviewActionType = this.props.reviewActionType === DECISION_TYPES.OMO_REQUEST ?
                'OMO' : 'Draft Decision';

              return `Draft Decision | Submit ${reviewActionType}`;
            }}
            render={this.routedSubmitDecision} />
          <PageRoute
            exact
            path="/queue/tasks/:vacolsId/dispositions/:action(add|edit)/:issueId?"
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/queue/tasks/:appealId/remands"
            title="Draft Decision | Select Issue Remand Reasons"
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/queue/tasks/:vacolsId/dispositions"
            title="Draft Decision | Select Dispositions"
            render={this.routedSelectDispositions} />
          <PageRoute
            exact
            path="/appeals/:vacolsId"
            title="Case Details | Caseflow"
            render={this.routedCaseDetail} />
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
  dropdownUrls: PropTypes.array,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => ({
  ..._.pick(state.caseSelect, 'caseSelectCriteria.searchQuery'),
  ..._.pick(state.queue.loadedQueue, 'appeals'),
  reviewActionType: state.queue.stagedChanges.taskDecision.type
});

export default connect(mapStateToProps)(QueueApp);
