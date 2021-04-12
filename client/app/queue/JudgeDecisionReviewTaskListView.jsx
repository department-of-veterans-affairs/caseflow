import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';
import PropTypes from 'prop-types';

import QueueTableBuilder from './QueueTableBuilder';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Alert from '../components/Alert';

import { judgeLegacyDecisionReviewTasksSelector } from './selectors';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState,
  showErrorMessage
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';

import COPY from '../../COPY';

const containerStyles = css({
  position: 'relative'
});

class JudgeDecisionReviewTaskListView extends React.PureComponent {
  componentWillUnmount = () => {
    this.props.resetSaveState();
    this.props.resetSuccessMessages();
    this.props.resetErrorMessages();
  }

  componentDidMount = () => {
    this.props.clearCaseSelectSearch();
    this.props.resetErrorMessages();
  };

  render = () => {
    const {
      messages,
      tasks
    } = this.props;

    return <AppSegment filledBackground styling={containerStyles}>
      {messages.error && <Alert type="error" title={messages.error.title}>
        {messages.error.detail}
      </Alert>}
      {messages.success && <Alert type="success" title={messages.success.title}>
        {messages.success.detail || COPY.JUDGE_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      <QueueTableBuilder assignedTasks={tasks} />
    </AppSegment>;
  };
}

const mapStateToProps = (state) => {
  const {
    ui: {
      messages
    }
  } = state;

  return {
    tasks: judgeLegacyDecisionReviewTasksSelector(state),
    messages
  };
};

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    clearCaseSelectSearch,
    resetErrorMessages,
    resetSuccessMessages,
    resetSaveState
  }, dispatch)
);

export default connect(mapStateToProps, mapDispatchToProps)(JudgeDecisionReviewTaskListView);

JudgeDecisionReviewTaskListView.propTypes = {
  tasks: PropTypes.array.isRequired,
  resetSaveState: PropTypes.func,
  resetSuccessMessages: PropTypes.func,
  resetErrorMessages: PropTypes.func,
  clearCaseSelectSearch: PropTypes.func,
  messages: PropTypes.shape({
    error: PropTypes.shape({
      title: PropTypes.string,
      detail: PropTypes.string
    }),
    success: PropTypes.shape({
      title: PropTypes.string,
      detail: PropTypes.string
    })
  })
};
