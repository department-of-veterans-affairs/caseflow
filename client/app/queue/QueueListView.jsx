import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { getDecisionTypeDisplay } from './utils';

import StatusMessage from '../components/StatusMessage';
import QueueTable from './QueueTable';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import {
  resetErrorMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import { fullWidth } from './constants';

class QueueListView extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = { displayConfirmationMessage: false };
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();

    if (this.props.saveSuccessful) {
      // to prevent the confirmation banner from being displayed after
      // navigating away, cache the save result in state
      this.setState({ displayConfirmationMessage: true });
      this.props.resetSaveState();
    }
  };

  getSaveConfirmationMessage = () => {
    const {
      taskDecision,
      taskDecision: {
        opts: {
          reviewing_judge_id: judgeId,
          veteran_name: vetName
        }
      },
      judges
    } = this.props;
    const fields = {
      type: getDecisionTypeDisplay(taskDecision),
      judge: judges[judgeId].full_name,
      veteran: vetName
    };

    return `${fields.type} for ${fields.veteran} has been marked completed and sent to ${fields.judge}.`;
  };

  render = () => {
    const noTasks = !_.size(this.props.tasks) && !_.size(this.props.appeals);
    let tableContent;

    if (noTasks) {
      tableContent = <StatusMessage title="Tasks not found">
        Sorry! We couldn't find any tasks for you.
      </StatusMessage>;
    } else {
      tableContent = <div>
        {this.state.displayConfirmationMessage &&
        <Alert type="success" title={this.getSaveConfirmationMessage()}>
          If you made a mistake please email your judge to resolve the issue.
        </Alert>
        }
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

const mapStateToProps = (state) => ({
  ..._.pick(state.queue.loadedQueue, 'tasks', 'appeals'),
  ..._.pick(state.ui.saveState, 'saveSuccessful'),
  ..._.pick(state.queue.pendingChanges, 'taskDecision'),
  judges: state.queue.judges
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSaveState
  }, dispatch)
});

export default connect(mapStateToProps, mapDispatchToProps)(QueueListView);
