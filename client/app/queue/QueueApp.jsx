import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';

import CaseSelectSearch from '../reader/CaseSelectSearch';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import { LOGO_COLORS } from '../constants/AppConstants';
import { connect } from 'react-redux';

class QueueApp extends React.PureComponent {
  routedQueueList = () => <QueueLoadingScreen {...this.props}>
    <CaseSelectSearch
      navigateToPath={(path) => window.location.href = `/reader/appeal${path}`}
      alwaysShowCaseSelectionModal
      feedbackUrl={this.props.feedbackUrl}
      searchSize="big"
      styling={this.getSearchStyling()} />
    <QueueListView {...this.props} />
  </QueueLoadingScreen>;

  getSearchStyling = () => css({
    '.section-search': {
      marginTop: '3rem',
      '> .usa-alert-error, > .usa-alert-info': {
        marginBottom: '1rem'
      },
      '> .usa-search-big': {
        '> .cf-search-input-with-close': {
          marginLeft: `calc(100% - ${this.props.isRequestingAppealsUsingVeteranId ? '60' : '56.5'}rem)`
        },
        '> span > .cf-submit': {
          width: '10.5rem'
        }
      }
    }
  });

  render = () => <BrowserRouter basename="/queue">
    <div>
      <NavigationBar
        defaultUrl="/"
        userDisplayName={this.props.userDisplayName}
        dropdownUrls={this.props.dropdownUrls}
        logoProps={{
          overlapColor: LOGO_COLORS.QUEUE.OVERLAP,
          accentColor: LOGO_COLORS.QUEUE.ACCENT
        }}
        appName="Queue">
        <div className="cf-wide-app section--queue-list">
          <PageRoute
            exact
            path="/"
            title="Your Queue | Caseflow Queue"
            render={this.routedQueueList} />
        </div>
      </NavigationBar>
      <Footer
        appName="Queue"
        feedbackUrl={this.props.feedbackUrl}
        buildDate={this.props.buildDate} />
    </div>
  </BrowserRouter>;
}

QueueApp.propTypes = {
  userDisplayName: PropTypes.string.isRequired,
  feedbackUrl: PropTypes.string.isRequired,
  userId: PropTypes.number.isRequired,
  dropdownUrls: PropTypes.array,
  buildDate: PropTypes.string
};

const mapStateToProps = (state) => _.pick(state.caseSelect,
  ['isRequestingAppealsUsingVeteranId', 'caseSelectCriteria.searchQuery']);

export default connect(mapStateToProps)(QueueApp);
