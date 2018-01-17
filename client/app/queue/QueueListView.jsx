import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import QueueTable from './QueueTable';
import StatusMessage from '../components/StatusMessage';

class QueueListView extends React.Component {
  // shouldFetchQueueList = () => true
  //
  // componentDidMount = () => {
  //   if (this.shouldFetchQueueList()) {
  //     this.props.fetchQueueListDetails();
  //   } else {
  //     this.props.onReceiveQueueListDetails();
  //   }
  // }

  render = () => {
    const noTasks = !_.size(this.props.tasks) && !_.size(this.props.appeals);

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          { noTasks ?
            <StatusMessage title="Tasks not found">
              Sorry! We couldn't find any tasks for you.<br/>
              Please try again or click <a href="/reader">go back to the document list.</a>
            </StatusMessage> :
            <QueueTable
              tasks={this.props.tasks}
              appeals={this.props.appeals}
            />
          }
        </div>
      </div>
    </div>;
  }
}

QueueListView.propTypes = {};

const mapStateToProps = (state, props) => {
  return {
    ..._.pick(state.loadedQueue, 'tasks', 'appeals')
  };
};

// const mapDispatchToProps = (dispatch) => ({
//   ...bindActionCreators({}, dispatch)
// });

export default connect(mapStateToProps)(QueueListView);
