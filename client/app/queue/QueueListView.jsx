import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { css } from 'glamor';

import StatusMessage from '../components/StatusMessage';
import QueueTable from './QueueTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';

class QueueListView extends React.PureComponent {
  componentDidMount = () => this.props.clearCaseSelectSearch();

  render = () => {
    const noTasks = !_.size(this.props.tasks) && !_.size(this.props.appeals);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title="Tasks not found">
        Sorry! We couldn't find any tasks for you.<br />
        Please try again or click <a href="/reader">go back to the document list.</a>
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 className="cf-push-left" {...headerStyling}>Your Queue</h1>
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
    clearCaseSelectSearch
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(QueueListView);
