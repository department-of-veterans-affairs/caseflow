import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import QueueTable from './QueueTable';
import StatusMessage from '../components/StatusMessage';

class QueueListView extends React.PureComponent {
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
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title="Tasks not found">
        Sorry! We couldn't find any tasks for you.<br/>
        Please try again or click <a href="/reader">go back to the document list.</a>
      </StatusMessage>
    } else {
      tableContent = <div>
        <h1 className="cf-push-left">Your Queue</h1>
        <QueueTable
          tasks={this.props.tasks}
          appeals={this.props.appeals}
        />
      </div>
    }

    return <div className="usa-grid">
      <div className="cf-app">
        <div className="cf-app-segment cf-app-segment--alt">
          {tableContent}
        </div>
      </div>
    </div>;
  }
}

QueueListView.propTypes = {};

const mapStateToProps = (state) => ({
  ..._.pick(state.loadedQueue, 'tasks', 'appeals')
});

// const mapDispatchToProps = (dispatch) => ({
//   ...bindActionCreators({}, dispatch)
// });

export default connect(mapStateToProps)(QueueListView);
