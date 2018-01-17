import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import NoSearchResults from '../reader/NoSearchResults';
import QueueTable from './QueueTable';

class QueueListView extends React.Component {
  shouldFetchQueueList = () => true

  componentDidMount = () => {
    if (this.shouldFetchQueueList()) {
      this.props.fetchQueueListDetails();
    } else {
      this.props.onReceiveQueueListDetails();
    }
  }

  render = () => {
    const noTasks = !_.size(this.props.tasks);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          { noTasks ?
            <NoSearchResults /> :
            <QueueTable />
          }
        </div>
      </div>
    </div>;
  }
}

QueueListView.propTypes = {};

const mapStateToProps = (state, props) => {
  return {};
};

const mapDispatchToProps = (dispatch) => {
  bindActionCreators({});
};

export default connect(mapStateToProps, mapDispatchToProps)(QueueListView);
