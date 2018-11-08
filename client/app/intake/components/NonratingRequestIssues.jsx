import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import DateSelector from '../../components/DateSelector';
import { ISSUE_CATEGORIES } from '../constants';
import _ from 'lodash';

export default class NonratingRequestIssuesUnconnected extends React.PureComponent {
  render() {
    const {
      nonRatingRequestIssues,
      newNonratingRequestIssue,
      setIssueCategory,
      setIssueDescription,
      setIssueDecisionDate
    } = this.props;

    const disableAddNonratingRequestIssue = _.some(nonRatingRequestIssues, (issue) => {
      return !issue.description;
    });

    const nonRatingRequestIssuesSection = _.map(nonRatingRequestIssues, (issue, issueId) => {
      return (
        <NonratingRequestIssue
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

    return <div>
      <h2>Enter other issue(s) for review</h2>
      <p>
      If the Veteran included any additional issues you cannot find in the list above,
      please note them below. Otherwise, leave the section blank.
      </p>
      <div>
        { nonRatingRequestIssuesSection }
      </div>

      <Button
        name="add-issue"
        onClick={newNonratingRequestIssue}
        classNames={['usa-button-secondary']}
        disabled={disableAddNonratingRequestIssue}
      >
      + Add issue
      </Button>
    </div>;
  }
}

class NonratingRequestIssue extends React.PureComponent {
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
      <div className="cf-nonrating-request-issue">
        <SearchableDropdown
          name="issue-category"
          label="Issue category"
          strongLabel
          placeholder="Select or enter..."
          options={ISSUE_CATEGORIES}
          value={category}
          onChange={(event) => this.handleCategoryChange(event)} />

        <TextField
          name="Issue description"
          strongLabel
          value={description}
          onChange={(event) => this.handleDescriptionChange(event)} />

        <DateSelector
          name="Issue date"
          label="Decision date"
          strongLabel
          value={decisionDate}
          required={category ? (category !== 'Unknown issue category') : false}
          onChange={(event) => this.handleDecisionDateChange(event)} />
      </div>
    );
  }
}
