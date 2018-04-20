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

  routedCaseDetail = (props) => <QueueLoadingScreen {...this.props}>
    <Breadcrumbs />
    <CaseDetailView
      vacolsId={props.match.params.vacolsId}
      featureToggles={this.props.featureToggles} />
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props}>
    <Breadcrumbs />
    <QueueDetailView
      vacolsId={props.match.params.vacolsId}
      featureToggles={this.props.featureToggles} />
  </QueueLoadingScreen>;

  routedSubmitDecision = (props) => <SubmitDecisionView
    vacolsId={props.match.params.vacolsId}
    nextStep="/" />;

  routedSelectDispositions = (props) => {
    const { vacolsId } = props.match.params;

    return <SelectDispositionsView
      vacolsId={vacolsId}
      prevStep={`/tasks/${vacolsId}`}
      nextStep={`/tasks/${vacolsId}/submit`} />;
  };

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/tasks/${props.match.params.vacolsId}/dispositions`}
    prevStep={`/tasks/${props.match.params.vacolsId}/dispositions`}
    {...props.match.params} />;

  routedSetIssueRemandReasons = (props) => <SelectRemandReasonsView
    nextStep={`/tasks/${props.match.params.appealId}/submit`}
    {...props.match.params} />;

  render = () => <BrowserRouter basename="/queue">
    <NavigationBar
      wideApp
      defaultUrl="/"
      userDisplayName={this.props.userDisplayName}
      dropdownUrls={this.props.dropdownUrls}
      logoProps={{
        overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
        accentColor: LOGO_COLORS.QUEUE.ACCENT
      }}
      appName="Queue">
      <AppFrame wideApp>
        <div className="cf-wide-app" {...appStyling}>
          <PageRoute
            exact
            path="/"
            title="Your Queue | Caseflow Queue"
            render={this.routedQueueList} />
          <PageRoute
            exact
            path="/tasks/:vacolsId"
            title="Draft Decision | Caseflow Queue"
            render={this.routedQueueDetail} />
          <PageRoute
            exact
            path="/tasks/:vacolsId/submit"
            title={() => {
              const reviewActionType = this.props.reviewActionType === DECISION_TYPES.OMO_REQUEST ?
                'OMO' : 'Draft Decision';

              return `Draft Decision | Submit ${reviewActionType}`;
            }}
            render={this.routedSubmitDecision} />
          <PageRoute
            exact
            path="/tasks/:vacolsId/dispositions/:action(add|edit)/:issueId?"
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/tasks/:appealId/remands"
            title="Draft Decision | Select Issue Remand Reasons"
            render={this.routedSetIssueRemandReasons} />
          <PageRoute
            exact
            path="/tasks/:vacolsId/dispositions"
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
        appName="Queue"
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
  reviewActionType: state.queue.pendingChanges.taskDecision.type
});

export default connect(mapStateToProps)(QueueApp);
