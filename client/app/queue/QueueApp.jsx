import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';
import querystring from 'querystring';

import CaseSelectSearch from '../reader/CaseSelectSearch';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import AppFrame from '../components/AppFrame';
import QueueDetailView from './QueueDetailView';
import { LOGO_COLORS } from '../constants/AppConstants';
import { connect } from 'react-redux';
import Reader from '../reader';

const appStyling = css({
  paddingTop: '3rem'
});

const searchStyling = (isRequestingAppealsUsingVeteranId) => css({
  '.section-search': {
    '& .usa-alert-info': {
      marginBottom: '1rem'
    },
    '& .cf-search-input-with-close': {
      marginLeft: `calc(100% - ${isRequestingAppealsUsingVeteranId ? '60' : '56.5'}rem)`
    },
    '& .cf-submit': {
      width: '10.5rem'
    }
  }
});

const basename = '/queue';

const segmentStyling = css({
  marginTop: '3rem'
});

class BackToQueueLink extends React.PureComponent {
  render() {
    const href = decodeURI(querystring.parse(this.props.location.search.slice(1)).backToPathname) || '/';
    let text = 'Back to Your Queue';

    if (href !== '/') {
      text = 'Back to Draft Decision';
    }

    return <div {...segmentStyling}>
      <Link href={`${basename}${href}`}>&lt; {text}</Link>
    </div>;
  }
}

class QueueApp extends React.PureComponent {
  getEmbeddedReader = () => {
    const passthroughReaderProps = _.pick(
      this.props, 'userDisplayName', 'dropdownUrls', 'feedbackUrl', 'featureToggles', 'pdfWorker', 'buildDate'
    );

    return <Reader embedded {...passthroughReaderProps} basename={basename} backToLink={BackToQueueLink} />;
  }

  routedQueueList = (props) => <QueueLoadingScreen {...this.props}>
    <CaseSelectSearch
      navigateToPath={(path) => window.location.href = `/reader/appeal${path}`}
      alwaysShowCaseSelectionModal
      feedbackUrl={this.props.feedbackUrl}
      searchSize="big"
      styling={searchStyling(this.props.isRequestingAppealsUsingVeteranId)} />
    <QueueListView {...this.props} location={props.location} />
  </QueueLoadingScreen>;

  routedQueueDetail = (props) => <QueueLoadingScreen {...this.props}>
    <Link to="/">&lt; Back to your queue</Link>
    <QueueDetailView vacolsId={props.match.params.vacolsId} location={props.location} />
  </QueueLoadingScreen>;

  render = () => <BrowserRouter basename={basename}>
    <NavigationBar
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
            breadcrumb="Your Queue"
            title="Your Queue | Caseflow Queue"
            render={this.routedQueueList} />
          <PageRoute
            exact
            path="/tasks/:vacolsId"
            breadcrumb="Draft Decision"
            title="Draft Decision | Caseflow Queue"
            render={this.routedQueueDetail} />
          <PageRoute
            path="/reader"
            title="Reader"
            breadcrumb="Reader"
            render={this.getEmbeddedReader} />
        </div>
      </AppFrame>
      <Footer
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
  ..._.pick(state.queue.loadedQueue, 'appeals')
});

export default connect(mapStateToProps)(QueueApp);
