import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import BoardGrant from '../components/BoardGrant';
import Disposition from '../components/Disposition';
import RecordRequest from '../components/RecordRequest';
import { DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { formatDate, formatDateStr } from '../../util/DateUtil';
import { longFormNameFromKey } from '../util';
import { completeTask, taskUpdateDefaultPage } from '../actions/task';
import { ErrorAlert } from '../components/Alerts';

class TaskPageUnconnected extends React.PureComponent {
  handleSave = (data) => {
    const successHandler = () => {
      // update to the completed tab
      this.props.taskUpdateDefaultPage(1);
      this.props.history.push(`/${this.props.businessLineUrl}`);
    };

    this.props.completeTask(this.props.task.id, this.props.businessLineUrl,
      data, this.props.task.claimant.name).then(successHandler.bind(this));
  }

  render = () => {
    const {
      appeal,
      businessLine,
      task,
      decisionIssuesStatus
    } = this.props;

    let errorAlert = null;

    if (decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.FAIL) {
      errorAlert = <ErrorAlert errorCode="decisionIssueUpdateFailed" />;
    }

    let detailedTaskView = null;

    if (task.type === 'Board Grant') {
      detailedTaskView = <BoardGrant handleSave={this.handleSave} />;
    } else if (task.type === 'Record Request') {
      detailedTaskView = <RecordRequest handleSave={this.handleSave} />;
    } else {
      detailedTaskView = <Disposition handleSave={this.handleSave} />;
    }

    return <div>
      { errorAlert }
      <h1>{businessLine}</h1>
      <div className="cf-review-details cf-gray-box">
        <div className="usa-grid-full">
          <div className="usa-width-one-half">
            <span className="cf-claimant-name">{task.claimant.name}</span>
            <strong className="cf-relationship">Relationship to Veteran</strong> {task.claimant.relationship}
          </div>
          <div className="usa-width-one-half cf-txt-r pad-top">
            <span className="cf-intake-date"><strong>Intake date</strong> {formatDate(task.created_at)}</span>
            <span>Veteran ID: {appeal.veteran.fileNumber}</span>
          </div>
        </div>
        <div className="usa-grid-full row-two">
          <div className="usa-width-one-half">
            { appeal.veteranIsNotClaimant ? `Veteran Name: ${appeal.veteran.name}` : '\u00a0' }
          </div>
          <div className="usa-width-one-half cf-txt-r">
            <div>SSN: {appeal.veteran.ssn || '[unknown]'}</div>
          </div>
        </div>
        <hr />
        <div className="usa-grid-full">
          <div className="usa-width-two-thirds">
            <div className="cf-form-details">
              <div><strong>Form being processed</strong> {longFormNameFromKey(appeal.formType)}</div>
              <div><strong>Informal conference requested</strong> {appeal.informalConference ? 'Yes' : 'No'}</div>
              <div><strong>Review by same office requested</strong> {appeal.sameOffice ? 'Yes' : 'No'}</div>
            </div>
          </div>
          <div className="usa-width-one-third">
            <div className="cf-receipt-date cf-txt-r">
              <div><strong>Form receipt date</strong> {formatDateStr(appeal.receiptDate)}</div>
            </div>
          </div>
        </div>
      </div>
      { detailedTaskView }
    </div>;
  }
}

TaskPageUnconnected.propTypes = {
  appeal: PropTypes.shape({
    veteran: PropTypes.object,
    formType: PropTypes.string,
    sameOffice: PropTypes.bool,
    informalConference: PropTypes.bool,
    veteranIsNotClaimant: PropTypes.bool,
    receiptDate: PropTypes.string
  }),
  task: PropTypes.shape({
    id: PropTypes.number,
    claimant: PropTypes.object,
    type: PropTypes.string,
    created_at: PropTypes.string
  }),
  businessLine: PropTypes.string,
  decisionIssuesStatus: PropTypes.object,
  taskUpdateDefaultPage: PropTypes.func,
  completeTask: PropTypes.func,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  businessLineUrl: PropTypes.string
};

const TaskPage = connect(
  (state) => ({
    appeal: state.appeal,
    businessLine: state.businessLine,
    businessLineUrl: state.businessLineUrl,
    task: state.task,
    decisionIssuesStatus: state.decisionIssuesStatus
  }),
  (dispatch) => bindActionCreators({
    completeTask,
    taskUpdateDefaultPage
  }, dispatch)
)(TaskPageUnconnected);

export default TaskPage;
