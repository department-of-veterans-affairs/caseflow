import React from 'react';
import { connect } from 'react-redux';

// import Button from '../../components/Button';
import SearchableDropdown from '../../components/SearchableDropdown';
import { DISPOSITION_OPTIONS } from '../constants';

class NonCompDecisionIssue extends React.PureComponent {
  constructor(props) {
    super(props);

    this.state = {
      disposition: '',
      description: '',
      issueIdx: props.index - 1
    };
  }

  handleDispositionChange = (value) => {
    this.setState({
      disposition: value
    });
  }

  dispositionOptions = () => {
    return DISPOSITION_OPTIONS.map((code) => {
      return {
        value: code,
        label: code
      };
    });
  }

  render = () => {
    const {
      issue,
      index
    } = this.props;

    let issueDate = issue.rating_issue_profile_date || issue.decision_date;

    return <div className="cf-decision">
      <hr />
      <div className="usa-grid-full">
        <h3>Issue #{index}</h3>
        <div className="cf-decision-details">
          <div className="desc">{issue.description}</div>
          <div className="date"><strong>Prior decision date:</strong> {issueDate}.</div>
        </div>
        <div className="usa-width-two-thirds">
          <div><strong>Decision description</strong> <span className="cf-optional">Optional</span></div>
          <textarea name={`description-issue-${index}`} value={this.state.description}></textarea>
        </div>
        <div className="usa-width-one-third cf-disposition">
          <SearchableDropdown
            name={`disposition-issue-${index}`}
            // empty label to get "true" value, nothing visible
            label=" "
            placeholder="Choose Disposition"
            options={this.dispositionOptions()}
            value={this.state.disposition}
            onChange={this.handleDispositionChange} />
        </div>
      </div>
    </div>;
  }
}

class NonCompDispositionsPage extends React.PureComponent {
  render = () => {
    const {
      appeal,
      businessLine,
      task
    } = this.props;

    return <div>
      <h1>{businessLine}</h1>
      <div className="cf-review-details">
        <div className="usa-grid-full">
          <div className="usa-width-one-half">
            <strong className="cf-claimant-name">{task.claimant.name}</strong>
            &nbsp;|&nbsp;
            <strong>Relationship to Veteran</strong> {task.claimant.relationship}
          </div>
          <div className="usa-width-one-half cf-txt-r">
            <span><strong>Intake date</strong> {appeal.receiptDate}</span>
            <span>Veteran ID: {appeal.veteran.fileNumber}</span>
          </div>
        </div>
        <div className="usa-grid-full">
          <div className="usa-width-one-half">
            { appeal.veteranIsNotClaimant ? `Veteran Name ${appeal.veteran.name}` : '' }
          </div>
          <div className="usa-width-one-half cf-txt-r">
            <span>SSN: TODO</span>
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
            appeal.requestIssues.map((issue, index) => {
              return <NonCompDecisionIssue key={`issue-${index}`} issue={issue} index={index + 1} />;
            })
          }
        </div>
      </div>
    </div>;
  }
}

const DispositionPage = connect(
  (state) => ({
    appeal: state.appeal,
    businessLine: state.businessLine,
    task: state.task
  })
)(NonCompDispositionsPage);

export default DispositionPage;
