import React from 'react';
import PropTypes from 'prop-types';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';
import { css } from 'glamor';

import CaseSelectSearch from '../reader/CaseSelectSearch';
import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '@department-of-veterans-affairs/appeals-frontend-toolkit/components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import { COLORS } from './constants';
import { connect } from 'react-redux';

const searchStyling = css({
  '.section-search': {
    '> .usa-alert-error': {
      marginBottom: '1rem'
    },
    '> .usa-search-big': {
      '> .cf-search-input-with-close': {
        marginLeft: 'calc(100% - 56.5rem)'
      },
      '> span > .cf-submit': {
        width: '10.5rem'
      }
    }
  }
});

class QueueApp extends React.PureComponent {
  routedQueueList = (props) => <QueueLoadingScreen {...this.props}>
    <div className="usa-grid">
      <CaseSelectSearch
        history={props.history}
        feedbackUrl={this.props.feedbackUrl}
        searchSize="big"
        styling={searchStyling} />
    </div>
    <QueueListView {...this.props} />
  </QueueLoadingScreen>;

  render = () => <BrowserRouter basename="/queue">
    <div>
      <NavigationBar
        defaultUrl="/"
        userDisplayName={this.props.userDisplayName}
        dropdownUrls={this.props.dropdownUrls}
        logoProps={{
          backgroundColor: COLORS.QUEUE_LOGO_BACKGROUND,
          overlapColor: COLORS.QUEUE_LOGO_OVERLAP,
          accentColor: COLORS.QUEUE_LOGO_PRIMARY
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

const mapStateToProps = (state) => _.pick(state.caseSelect.caseSelectCriteria, 'searchQuery');

export default connect(mapStateToProps)(QueueApp);
