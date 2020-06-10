import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import Alert from '../components/Alert';
import QueueTableBuilder from './QueueTableBuilder';

import {
  resetErrorMessages,
  resetSuccessMessages,
  resetSaveState
} from './uiReducer/uiActions';
import { clearCaseSelectSearch } from '../reader/CaseSelect/CaseSelectActions';
import { judgeDecisionReviewTasksSelector } from './selectors';

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
    const reviewableCount = tasks.length;

    return <AppSegment filledBackground styling={containerStyles}>
      {messages.error && <Alert type="error" title={messages.error.title}>
        {messages.error.detail}
      </Alert>}
      {messages.success && <Alert type="success" title={messages.success.title}>
        {messages.success.detail || COPY.JUDGE_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      {reviewableCount === 0 && <p {...css({ textAlign: 'center',
        marginTop: '3rem' })}>
        {COPY.NO_CASES_IN_QUEUE_MESSAGE}<b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p>}
      <QueueTableBuilder assignedTasks={tasks} />
    </AppSegment>;
  };
}

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

const mapStateToProps = (state) => {
  const {
    ui: {
      messages
    }
  } = state;

  return {
    tasks: judgeDecisionReviewTasksSelector(state),
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
