import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import { ISSUE_CATEGORIES } from '../constants';

export class NonRatedIssueUnconnected extends React.PureComponent {
  handleCategoryChange(event) {
    this.props.setIssueCategory(this.props.issueId, event.value);
  }

  handleDescriptionChange(event) {
    this.props.setIssueDescription(this.props.issueId, event);
  }

  render () {
    const { nonRatedIssues } = this.props;

    return (
      <div className="cf-non-rated-issue" key={this.props.key}>
        <SearchableDropdown
          name="issue-category"
          label="Issue category"
          placeholder="Select or enter..."
          options={ISSUE_CATEGORIES}
          value={nonRatedIssues[this.props.issueId] ? nonRatedIssues[this.props.issueId].issueCategory : null}
          onChange={(event) => this.handleCategoryChange(event)} />

        <TextField
          name="Issue description"
          required
          value={nonRatedIssues[this.props.issueId] ? nonRatedIssues[this.props.issueId].issueDescription : null}
          onChange={(event) => this.handleDescriptionChange(event)} />

        <Button
          name="save-issue"
          legacyStyling={false}
        >
            Save
        </Button>
      </div>
    );
  }
}

export class AddIssueButtonUnconnected extends React.PureComponent {
  render = () =>
    <Button
      name="add-issue"
      onClick={this.props.addNonRatedIssue}
      legacyStyling={false}
    >
    + Add issue
    </Button>;
}
