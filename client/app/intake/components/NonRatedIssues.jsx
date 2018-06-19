import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import { ISSUE_CATEGORIES } from '../constants';
import _ from 'lodash';

export default class NonRatedIssuesUnconnected extends React.PureComponent {
  render() {
    const {
      nonRatedIssues,
      addNonRatedIssue,
      setIssueCategory,
      setIssueDescription
    } = this.props;

    let disableAddNonRatedIssue;

    if (Object.keys(nonRatedIssues).length === 0) {
      disableAddNonRatedIssue = false;
    } else {
      disableAddNonRatedIssue = Boolean(_.reduce(nonRatedIssues, (result, issue) => {
        return issue.description ? result : result - 1;
      }, 0));
    }

    const nonRatedIssuesSection = _.map(nonRatedIssues, (issue, issueId) => {
      return (
        <NonRatedIssue
          key={issueId}
          id={issueId}
          category={issue.category}
          description={issue.description}
          setCategory={setIssueCategory}
          setDescription={setIssueDescription}
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
    this.props.setCategory(this.props.id, event.value);
  }

  handleDescriptionChange(event) {
    this.props.setDescription(this.props.id, event);
  }

  render () {
    const { category, description } = this.props;

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
      </div>
    );
  }
}
