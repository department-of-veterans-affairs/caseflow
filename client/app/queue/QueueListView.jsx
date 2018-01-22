import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import StatusMessage from '../components/StatusMessage';

import QueueTable from './QueueTable';
import { showSearchBar, hideSearchBar } from './QueueActions';

class QueueListView extends React.PureComponent {
  componentDidMount = () => this.props.showSearchBar();
  componentWillUnmount = () => this.props.hideSearchBar();

  render = () => {
    const noTasks = !_.size(this.props.tasks) && !_.size(this.props.appeals);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title="Tasks not found">
        Sorry! We couldn't find any tasks for you.<br/>
        Please try again or click <a href="/reader">go back to the document list.</a>
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 className="cf-push-left">Your Queue</h1>
        <QueueTable
          tasks={this.props.tasks}
          appeals={this.props.appeals}
        />
      </div>;
    }

    return <div className="cf-app-segment cf-app-segment--alt">
      {tableContent}
    </div>;
  };
}

QueueListView.propTypes = {
  tasks: PropTypes.arrayOf(PropTypes.object).isRequired,
  appeals: PropTypes.arrayOf(PropTypes.object).isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.loadedQueue, 'tasks', 'appeals')
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    showSearchBar,
    hideSearchBar
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(QueueListView);
