import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';
import StringUtil from '../util/StringUtil';

import CaseSelectSearch from '../reader/CaseSelectSearch';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import AppFrame from '../components/AppFrame';
import QueueDetailView from './QueueDetailView';
import SubmitDecisionView from './SubmitDecisionView';
import SelectDispositionsView from './SelectDispositionsView';
import AddEditIssueView from './AddEditIssueView';
import { LOGO_COLORS } from '../constants/AppConstants';
import Breadcrumbs from './components/BreadcrumbManager';

const appStyling = css({ paddingTop: '3rem' });
const searchStyling = (isRequestingAppealsUsingVeteranId) => css({
  '.section-search': {
    '& .usa-alert-info, & .usa-alert-error': {
      marginBottom: '1.5rem',
      marginTop: 0
    },
    '& .cf-search-input-with-close': {
      marginLeft: `calc(100% - ${isRequestingAppealsUsingVeteranId ? '60' : '56.5'}rem)`
    },
    '& .cf-submit': {
      width: '10.5rem'
    }
  }
});

class QueueApp extends React.PureComponent {
  routedQueueList = () => <QueueLoadingScreen {...this.props}>
    <CaseSelectSearch
      navigateToPath={(path) => {
        const redirectUrl = encodeURIComponent(window.location.pathname);

        location.href = `/reader/appeal${path}?queue_redirect_url=${redirectUrl}`;
      }}
      alwaysShowCaseSelectionModal
      feedbackUrl={this.props.feedbackUrl}
      searchSize="big"
      styling={searchStyling(this.props.isRequestingAppealsUsingVeteranId)} />
    <QueueListView {...this.props} />
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props}>
    <Breadcrumbs />
    <QueueDetailView
      vacolsId={props.match.params.vacolsId}
      featureToggles={this.props.featureToggles} />
  </QueueLoadingScreen>;

  routedSubmitDecision = (props) => {
    const { vacolsId } = props.match.params;
    const appeal = this.props.appeals[vacolsId].attributes;

    return <SubmitDecisionView
      vacolsId={vacolsId}
      vbmsId={appeal.vbms_id}
      prevStep={`/tasks/${vacolsId}`}
      nextStep="/" />;
  };

  routedSelectDispositions = (props) => {
    const { vacolsId } = props.match.params;
    const appeal = this.props.appeals[vacolsId].attributes;

    return <SelectDispositionsView
      vacolsId={vacolsId}
      vbmsId={appeal.vbms_id}
      prevStep={`/tasks/${vacolsId}`}
      nextStep={`/tasks/${vacolsId}/submit`} />;
  };

  routedAddEditIssue = (props) => <AddEditIssueView
    nextStep={`/tasks/${props.match.params.vacolsId}/dispositions`}
    prevStep={`/tasks/${props.match.params.vacolsId}/dispositions`}
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
              const reviewActionType = this.props.reviewActionType === 'omo' ? 'OMO' : 'Draft Decision';

              return `Draft Decision | Submit ${reviewActionType}`;
            }}
            render={this.routedSubmitDecision} />
          <PageRoute
            exact
            path="/tasks/:vacolsId/dispositions/:action/:issueId"
            title={(props) => `Draft Decision | ${StringUtil.titleCase(props.match.params.action)} Issue`}
            render={this.routedAddEditIssue} />
          <PageRoute
            exact
            path="/tasks/:vacolsId/dispositions"
            title="Draft Decision | Select Dispositions"
            render={this.routedSelectDispositions} />
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
  dropdownUrls: PropTypes.array,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => ({
  ..._.pick(state.caseSelect, ['isRequestingAppealsUsingVeteranId', 'caseSelectCriteria.searchQuery']),
  ..._.pick(state.queue.loadedQueue, 'appeals'),
  reviewActionType: state.queue.pendingChanges.taskDecision.type
});

export default connect(mapStateToProps)(QueueApp);
