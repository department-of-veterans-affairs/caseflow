import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import QueueTableBuilder from './QueueTableBuilder';
import Alert from '../components/Alert';

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
    const { tasks, error, success } = this.props;
    const noCasesMessage = tasks.length === 0 ?
      <p>
        {COPY.NO_CASES_IN_QUEUE_MESSAGE}
        <b><Link to="/search">{COPY.NO_CASES_IN_QUEUE_LINK_TEXT}</Link></b>.
      </p> : '';

    return <AppSegment filledBackground styling={containerStyles}>
      {error && <Alert type="error" title={error.title}>
        {error.detail}
      </Alert>}
      {success && <Alert type="success" title={success.title}>
        {success.detail || COPY.ATTORNEY_QUEUE_TABLE_SUCCESS_MESSAGE_DETAIL}
      </Alert>}
      {noCasesMessage}
      <QueueTableBuilder assignedTasks={tasks}/>
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
    success: messages.success,
    error: messages.error
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
