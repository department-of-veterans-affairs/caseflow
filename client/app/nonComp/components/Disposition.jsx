import React from 'react';
import { connect } from 'react-redux';
import update from 'immutability-helper';

import { formatDateStr, formatDateStrUtc } from '../../util/DateUtil';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';
import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextareaField from '../../components/TextareaField';

import { DISPOSITION_OPTIONS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import {
  formatDecisionIssuesFromRequestIssues,
  formatRequestIssuesWithDecisionIssues,
  buildDispositionSubmission } from '../util';

class NonCompDecisionIssue extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      issueIdx: props.index
    };
  }

  handleDispositionChange = (option) => {
    this.props.onDispositionChange(this.state.issueIdx, option && option.value);
  }

  dispositionOptions = () => {
    const isSupplementalClaim = this.props.issue.review_request_title === 'Supplemental Claim';

    return DISPOSITION_OPTIONS.filter((code) => {
      return !isSupplementalClaim || code !== 'DTA Error';
    }).map((code) => {
      return {
        value: code,
        label: code
      };
    });
  }

  handleDescriptionChange = (value) => {
    this.props.onDescriptionChange(this.state.issueIdx, value);
  }

  render = () => {
    const {
      issue,
      index,
      disabled
    } = this.props;
    let issueDate = formatDateStr(issue.rating_issue_profile_date || issue.decision_date);

    return <div className="cf-decision">
      <hr />
      <div className="usa-grid-full">
        <h3>Issue #{index + 1}</h3>
        <div className="cf-decision-details">
          <div className="desc">{issue.description}</div>
          <div className="date"><strong>Prior decision date:</strong> {issueDate}.</div>
        </div>
        <div className="usa-width-two-thirds">
          <div><strong>Decision description</strong> <span className="cf-optional">Optional</span></div>
          <TextareaField name={`description-issue-${index}`}
            label={`description-issue-${index}`}
            hideLabel
            value={this.props.decisionDescription}
            disabled={disabled}
            onChange={this.handleDescriptionChange} />
        </div>
        <div className="usa-width-one-third cf-disposition">
          <SearchableDropdown
            readOnly={disabled}
            name={`disposition-issue-${index}`}
            label={`disposition-issue-${index}`}
            hideLabel
            placeholder="Select Disposition"
            options={this.dispositionOptions()}
            value={this.props.decisionDisposition}
            onChange={this.handleDispositionChange} />
        </div>
      </div>
    </div>;
  }
}

class NonCompDispositions extends React.PureComponent {
  constructor(props) {
    super(props);

    let today = formatDateStr(new Date());

    this.state = {
      requestIssues: formatRequestIssuesWithDecisionIssues(
        this.props.appeal.requestIssues, this.props.appeal.decisionIssues),
      decisionDate: today,
      isFilledOut: false
    };
  }

  handleDecisionDate = (value) => {
    this.setState({ decisionDate: value }, this.checkFormFilledOut);
  }

  handleSave = () => {
    const decisionIssues = formatDecisionIssuesFromRequestIssues(this.state.requestIssues);
    const dispositionData = buildDispositionSubmission(decisionIssues, this.state.decisionDate);

    this.props.handleSave(dispositionData);
  }

  checkFormFilledOut = () => {
    // check if all dispositions have values & date is set
    const allDispositionsSet = this.state.requestIssues.every(
      (requestIssue) => Boolean(requestIssue.decisionIssue.disposition));

    this.setState({ isFilledOut: allDispositionsSet && Boolean(this.state.decisionDate) });
  }

  onDecisionIssueDispositionChange = (requestIssueIndex, value) => {
    const newRequestIssues = update(this.state.requestIssues,
      { [requestIssueIndex]: { decisionIssue: { disposition: { $set: value } } } });

    this.setState({ requestIssues: newRequestIssues }, this.checkFormFilledOut);
  }

  onDecisionIssueDescriptionChange = (requestIssueIndex, value) => {
    const newRequestIssues = update(this.state.requestIssues,
      { [requestIssueIndex]: { decisionIssue: { description: { $set: value } } } });

    this.setState({ requestIssues: newRequestIssues });
  }

  render = () => {
    const {
      appeal,
      decisionIssuesStatus,
      task
    } = this.props;

    let completeDiv = null;

    let decisionDate = this.state.decisionDate;

    if (appeal.decisionIssues.length > 0) {
      decisionDate = formatDateStrUtc(appeal.decisionIssues[0].caseflowDecisionDate);
    }

    if (!task.closed_at) {
      completeDiv = <React.Fragment>
        <div className="cf-txt-r">
          <a className="cf-cancel-link" href={`${task.tasks_url}`}>Cancel</a>
          <Button className="usa-button"
            name="submit-update"
            loading={decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS}
            disabled={!this.state.isFilledOut} onClick={this.handleSave}>Complete</Button>
        </div>
      </React.Fragment>;
    }

    return <div>
      <div className="cf-decisions">
        <div className="usa-grid-full">
          <div className="usa-width-one-half">
            <h2>Decision</h2>
            <div>Review each issue and assign the appropriate dispositions.</div>
          </div>
          <div className="usa-width-one-half cf-txt-r">
            <a className="cf-link-btn" href={appeal.editIssuesUrl}>
              Edit Issues
            </a>
          </div>
        </div>
        <div className="cf-decision-list">
          {
            this.state.requestIssues.map((issue, index) => {
              return <NonCompDecisionIssue key={`issue-${index}`} issue={issue} index={index}
                onDispositionChange={this.onDecisionIssueDispositionChange}
                onDescriptionChange={this.onDecisionIssueDescriptionChange}
                decisionDescription={issue.decisionIssue.description}
                decisionDisposition={issue.decisionIssue.disposition}
                disabled={Boolean(task.closed_at)}
              />;
            })
          }
        </div>
      </div>
      <div className="cf-gray-box">
        <div className="cf-decision-date">
          <InlineForm>
            <DateSelector
              label="Thank you for completing your decision in Caseflow. Please indicate the decision date."
              name="decision-date"
              value={decisionDate}
              onChange={this.handleDecisionDate}
              readOnly={Boolean(task.closed_at)}
            />
          </InlineForm>
        </div>
      </div>
      { completeDiv }
    </div>;
  }
}

const Dispositions = connect(
  (state) => ({
    appeal: state.appeal,
    task: state.task,
    decisionIssuesStatus: state.decisionIssuesStatus
  })
)(NonCompDispositions);

export default Dispositions;
