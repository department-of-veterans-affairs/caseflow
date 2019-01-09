import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import { formatDate } from '../../util/DateUtil';
import InlineForm from '../../components/InlineForm';
import DateSelector from '../../components/DateSelector';
import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';

import { ErrorAlert } from '../components/Alerts';
import { DISPOSITION_OPTIONS, DECISION_ISSUE_UPDATE_STATUS } from '../constants';
import { longFormNameFromShort, formatDecisionIssuesFromRequestIssues, formatRequestIssuesWithDecisionIssues } from '../util';
import { taskUpdateDecisionIssues, taskUpdateDefaultPage } from '../actions/task';

class NonCompDecisionIssue extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      issueIdx: props.index
    };
  }

  handleDispositionChange = (option) => {
    this.props.onDispositionChange(this.state.issueIdx, option.value);
  }

  dispositionOptions = () => {
    return DISPOSITION_OPTIONS.map((code) => {
      return {
        value: code,
        label: code
      };
    });
  }

  handleDescriptionChange = (event) => {
    this.props.onDescriptionChange(this.state.issueIdx, event.target.value);
  }

  render = () => {
    const {
      issue,
      index
    } = this.props;
    let issueDate = formatDate(issue.rating_issue_profile_date || issue.decision_date);

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
          <textarea name={`description-issue-${index}`} value={this.props.decisionDescription || undefined} onChange={this.handleDescriptionChange}></textarea>
        </div>
        <div className="usa-width-one-third cf-disposition">
          <SearchableDropdown
            name={`disposition-issue-${index}`}
            // empty label to get "true" value, nothing visible
            label=" "
            placeholder="Select Disposition"
            options={this.dispositionOptions()}
            value={this.props.decisionDisposition}
            onChange={this.handleDispositionChange} />
        </div>
      </div>
    </div>;
  }
}

class NonCompDispositionsPage extends React.PureComponent {
  constructor(props) {
    super(props);

    let today = formatDate(new Date());

    this.state = {
      requestIssues: formatRequestIssuesWithDecisionIssues(this.props.appeal.requestIssues, this.props.appeal.decisionIssues),
      decisionDate: today,
      isFilledOut: false
    };
  }

  handleDecisionDate = (value) => {
    this.setState({ decisionDate: value });
    this.checkFormFilledOut();
  }

  handleSave = () => {
    const decisionIssues = formatDecisionIssuesFromRequestIssues(this.state.requestIssues);

    function successHandler() {
      // update to the completed tab
      this.props.taskUpdateDefaultPage(1);
      this.props.history.push(`/${this.props.businessLineUrl}`);
    }

    this.props.taskUpdateDecisionIssues(this.props.task.id, this.props.businessLineUrl,
      decisionIssues, this.props.appeal.veteran).then(successHandler.bind(this));
  }

  checkFormFilledOut = () => {
    // check if all dispositions have values & date is set
    const allDispositionsSet = this.state.requestIssues.every((requestIssue) => Boolean(requestIssue.decisionIssue.disposition));
    this.setState({isFilledOut: allDispositionsSet && Boolean(this.state.decisionDate)})
  }

  onDecisionIssueDispositionChange = (requestIssueIndex, value) => {
    let newRequestIssues = this.state.requestIssues;
    newRequestIssues[requestIssueIndex].decisionIssue.disposition = value;
    this.setState({requestIssues: newRequestIssues});
    this.checkFormFilledOut();
  }

  onDecisionIssueDescriptionChange = (requestIssueIndex, value) => {
    let newRequestIssues = this.state.requestIssues;
    newRequestIssues[requestIssueIndex].decisionIssue.description = value;
    this.setState({requestIssues: newRequestIssues});
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
      errorAlert = <ErrorAlert errorCode="decisionIssueUpdateFailed"/>
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
            { appeal.veteranIsNotClaimant ? `Veteran Name ${appeal.veteran.name}` : '\u00a0' }
          </div>
          <div className="usa-width-one-half cf-txt-r">
            <div>SSN: {appeal.veteran.ssn || '[unknown]'}</div>
          </div>
        </div>
        <hr />
        <div className="usa-grid-full">
          <div className="usa-width-two-thirds">
            <div className="cf-form-details">
              <div><strong>Form being processed</strong> {longFormNameFromShort(task.type)}</div>
              <div><strong>Informal conference requested</strong> {appeal.informalConference ? 'Yes' : 'No'}</div>
              <div><strong>Review by same office requested</strong> {appeal.sameOffice ? 'Yes' : 'No'}</div>
            </div>
          </div>
          <div className="usa-width-one-third">
            <div className="cf-receipt-date cf-txt-r">
              <div><strong>Form receipt date</strong> {formatDate(appeal.receiptDate)}</div>
            </div>
          </div>
        </div>
      </div>
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
              value={this.state.decisionDate}
              onChange={this.handleDecisionDate}
            />
          </InlineForm>
        </div>
      </div>
      <div className="cf-txt-r">
        <a className="cf-cancel-link" href={`/decision_reviews/${businessLine}`}>Cancel</a>
        <Button className="usa-button"
          name="submit-update"
          loading={decisionIssuesStatus.update === DECISION_ISSUE_UPDATE_STATUS.IN_PROGRESS}
          disabled={!this.state.isFilledOut} onClick={this.handleSave}>Complete</Button>
      </div>
    </div>;
  }
}

const DispositionPage = connect(
  (state) => ({
    appeal: state.appeal,
    businessLine: state.businessLine,
    businessLineUrl: state.businessLineUrl,
    task: state.task,
    decisionIssuesStatus: state.decisionIssuesStatus
  }),
  (dispatch) => bindActionCreators({
    taskUpdateDecisionIssues,
    taskUpdateDefaultPage
  }, dispatch)
)(NonCompDispositionsPage);

export default DispositionPage;
