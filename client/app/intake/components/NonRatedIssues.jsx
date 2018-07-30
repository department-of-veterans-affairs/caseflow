import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import DateSelector from '../../components/DateSelector';
import { ISSUE_CATEGORIES } from '../constants';
import _ from 'lodash';

export default class NonRatedIssuesUnconnected extends React.PureComponent {
  render() {
    const {
      nonRatedIssues,
      addNonRatedIssue,
      setIssueCategory,
      setIssueDescription,
      setIssueDecisionDate
    } = this.props;

    const disableAddNonRatedIssue = _.some(nonRatedIssues, (issue) => {
      return !issue.description;
    });

    const nonRatedIssuesSection = _.map(nonRatedIssues, (issue, issueId) => {
      return (
        <NonRatedIssue
          key={issueId}
          id={issueId}
          category={issue.category}
          description={issue.description}
          decisionDate={issue.decisionDate}
          setCategory={setIssueCategory}
          setDescription={setIssueDescription}
          setIssueDecisionDate={setIssueDecisionDate}
        />
      );
    });

    return <div className="cf-non-rated-issues">
      <h2>Enter other issue(s) for review</h2>
      <p>
      If the Veteran included any additional issues you cannot find in the list above,
      please note them below. Otherwise, leave the section blank.
      </p>
      <div>
        { nonRatedIssuesSection }
      </div>

      <Button
        name="add-issue"
        onClick={addNonRatedIssue}
        legacyStyling={false}
        disabled={disableAddNonRatedIssue}
      >
      + Add issue
      </Button>
    </div>;
  }
}

class NonRatedIssue extends React.PureComponent {
  handleCategoryChange(event) {
    this.props.setCategory(this.props.id, event ? event.value : null);
  }

  handleDescriptionChange(event) {
    this.props.setDescription(this.props.id, event);
  }

  handleDecisionDateChange(event) {
    this.props.setIssueDecisionDate(this.props.id, event);
  }

  render () {
    const { category, description, decisionDate } = this.props;

    return (
      <div className="cf-non-rated-issue">
        <SearchableDropdown
          name="issue-category"
          label="Issue category"
          placeholder="Select or enter..."
          options={ISSUE_CATEGORIES}
          value={category}
          required
          onChange={(event) => this.handleCategoryChange(event)} />

        <TextField
          name="Issue description"
          value={description}
          required
          onChange={(event) => this.handleDescriptionChange(event)} />

        <DateSelector
          name="Issue date"
          label="Decision date"
          value={decisionDate}
          required={category ? (category !== 'Unknown issue category') : false}
          onChange={(event) => this.handleDecisionDateChange(event)} />
      </div>
    );
  }
}
