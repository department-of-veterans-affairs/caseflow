import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import _ from 'lodash';

import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';
import * as Constants from './constants';

export default class QueueManager extends React.PureComponent {
  routedQueueList = (props) => {
    const { vacolsId } = props.match.params;

    return <QueueLoadingScreen vacolsId={vacolsId}>
      <QueueListView {...props} />
    </QueueLoadingScreen>;
  };

  render = () => {
    return <BrowserRouter basename="/queue">
      <div>
        <NavigationBar
          defaultUrl="/"
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          logoProps={{
            backgroundColor: Constants.QUEUE_LOGO_BACKGROUND_COLOR,
            overlapColor: Constants.QUEUE_LOGO_OVERLAP_COLOR,
            accentColor: Constants.QUEUE_COLOR
          }}
          appName="Queue">
          <div className="cf-wide-app">
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
  };
}

QueueManager.propTypes = {
  userDisplayName: PropTypes.string,
  dropdownUrls: PropTypes.array,
  feedbackUrl: PropTypes.string,
  buildDate: PropTypes.string
};
