import React from 'react';
import { connect } from 'react-redux';

import Button from '../../components/Button';
import { DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import Checkbox from '../../components/Checkbox';
import { formatDate } from '../../util/DateUtil';
import { formatRequestIssuesWithDecisionIssues } from '../util';

class BoardGrantIssue extends React.PureComponent {
  render = () => {
    const {
      issue,
      index
    } = this.props;

    let issueDate = formatDate(issue.decisionIssue.promulgationDate);

    return <div className="cf-decision">
      <hr />
      <div className="usa-grid-full">
        <h3>Issue #{index + 1} - <span className="cf-success">GRANTED</span></h3>
        <div className="cf-decision-details">
          <div className="desc">{issue.description}</div>
          <div className="date"><strong>Prior decision date:</strong> {issueDate}.</div>
        </div>
        <div className="usa-width-full">
          <div><strong>Decision description</strong></div>
          <div>
            {issue.decisionIssue.description}
          </div>
        </div>
      </div>
    </div>;
  }
}

class BoardGrantUnconnected extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      isEffectuated: Boolean(this.props.task.completed_at)
    };
  }

  handleEffectuatedClick = () => {
    this.setState({ isEffectuated: !this.state.isEffectuated });
  }

  handleSave = () => {
    this.props.handleSave({});
  }

  render = () => {
    const {
      appeal,
      decisionIssuesStatus,
      task
    } = this.props;

    let completeDiv = null;

    if (!task.completed_at) {
      completeDiv = <React.Fragment>
        <div className="cf-gray-box">
          <div className="cf-decision-date">
            <Checkbox
              vertical
              onChange={this.handleEffectuatedClick}
              value={this.state.isEffectuated}
              disabled={Boolean(task.completed_at)}
              name="isEffectuated"
              label="I certify these benefits have been effectuated." />
          </div>
        </div>
        <div className="cf-txt-r">
          <a className="cf-cancel-link" href={`${task.tasks_url}`}>Cancel</a>
          <Button className="usa-button"
            name="submit-update"
            loading={decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS}
            disabled={!this.state.isEffectuated} onClick={this.handleSave}>Complete</Button>
        </div>
      </React.Fragment>;
    }

    const requestIssuesWithDecisionIssues = formatRequestIssuesWithDecisionIssues(
      appeal.requestIssues, appeal.decisionIssues).
      filter((requestIssue) =>
        requestIssue.decisionIssue.disposition === 'allowed'
      );

    return <div>
      <div className="cf-decisions">
        <div className="usa-grid-full">
          <div className="usa-width-one-half">
            <h2>Board Grants</h2>
          </div>
        </div>
        <div className="cf-decision-list">
          {
            requestIssuesWithDecisionIssues.map((issue, index) => {
              return <BoardGrantIssue key={`issue-${index}`} issue={issue} index={index} />;
            })
          }
        </div>
      </div>
      { completeDiv }
    </div>;
  }
}

const BoardGrant = connect(
  (state) => ({
    appeal: state.appeal,
    businessLine: state.businessLine,
    task: state.task,
    decisionIssuesStatus: state.decisionIssuesStatus
  })
)(BoardGrantUnconnected);

export default BoardGrant;
