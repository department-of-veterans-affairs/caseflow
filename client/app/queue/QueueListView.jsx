import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import QueueTable from './QueueTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { resetErrorMessages } from './uiReducer/actions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';

class QueueListView extends React.PureComponent {
  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  }

  render = () => {
    const noTasks = !_.size(this.props.tasks) && !_.size(this.props.appeals);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title="Tasks not found">
        Sorry! We couldn't find any tasks for you.
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 className="cf-push-left" {...fullWidth}>Your Queue</h1>
        <QueueTable />
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

QueueListView.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => _.pick(state.queue.loadedQueue, 'tasks', 'appeals');

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(QueueListView);
