import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

import StatusMessage from '../components/StatusMessage';
import AttorneyTaskTable from './AttorneyTaskTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';

class AttorneyTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();

    if (_.some(this.props.tasks, (task) => !task.attributes.task_id)) {
      this.props.showErrorMessage({
        title: 'Some cases need preliminary DAS assignments',
        detail: `Cases marked with exclamation points need to be assigned 
        to you through DAS. Please contact your judge or senior counsel to 
        create preliminary DAS assignments.`
      });
    }
  };

  render = () => {
    const { messages } = this.props;
    const noTasks = !_.size(this.props.tasks) && !_.size(this.props.appeals);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title="Tasks not found">
        Sorry! We couldn't find any tasks for you.
      </StatusMessage>;
    } else {
      tableContent = <div>
        <h1 {...fullWidth}>Your Queue</h1>
        {messages.error && <Alert type="error" title={messages.error.title}>
          {messages.error.detail}
        </Alert>}
        {messages.success && <Alert type="success" title={messages.success}>
          If you made a mistake please email your judge to resolve the issue.
        </Alert>}
        <AttorneyTaskTable featureToggles={this.props.featureToggles} />
      </div>;
    }

    return <AppSegment filledBackground>
      {tableContent}
    </AppSegment>;
  };
}

AttorneyTaskListView.propTypes = {
  tasks: PropTypes.object.isRequired,
  appeals: PropTypes.object.isRequired
};

const mapStateToProps = (state) => ({
  ..._.pick(state.queue.loadedQueue, 'tasks', 'appeals'),
  ..._.pick(state.ui, 'messages'),
  ..._.pick(state.queue.stagedChanges, 'taskDecision'),
  judges: state.queue.judges
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState,
    showErrorMessage
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(AttorneyTaskListView);
