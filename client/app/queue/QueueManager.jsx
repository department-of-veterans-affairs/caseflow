import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { BrowserRouter } from 'react-router-dom';
import { getQueryParams } from '../util/QueryParamsUtil';
import _ from 'lodash';

import PageRoute from '../components/PageRoute';
import NavigationBar from '../components/NavigationBar';
import Footer from '../components/Footer';
import QueueLoadingScreen from './QueueLoadingScreen';
import QueueListView from './QueueListView';

class QueueManager extends React.Component {
  routedQueueList = (props) => {
    const { vacolsId } = props.match.params;

    return <QueueLoadingScreen vacolsId={vacolsId}>
      <QueueListView {...props} />
    </QueueLoadingScreen>;
  };

  routedQueueDetail = (props) => {
    debugger;
  };

  render = () => {
    return <BrowserRouter basename="/queue">
      <div>
        <NavigationBar
          defaultUrl="/"
          userDisplayName={this.props.userDisplayName}
          dropdownUrls={this.props.dropdownUrls}
          appName="Queue">
          <div className="cf-wide-app section--queue-list">
            <PageRoute
              exact
              path="/"
              title="Your Queue | Caseflow Queue"
              render={this.routedQueueList}/>
            <PageRoute
              exact
              path="/:user_id"
              title="Draft Decision | Caseflow Queue"
              render={this.routedQueueDetail}/>
          </div>
        </NavigationBar>
        <Footer
          appName="Queue"
          feedbackUrl={this.props.feedbackUrl}
          buildDate={this.props.buildDate}/>
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

const mapStateToProps = (state) => {
  return {};
};

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({}, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(QueueManager);
