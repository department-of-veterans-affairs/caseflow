import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import { ISSUE_CATEGORIES } from '../constants';

export class NonRatedIssueUnconnected extends React.PureComponent {
  handleCategoryChange(event) {
    this.props.setIssueCategory(this.props.id, event.value);
  }

  handleDescriptionChange(event) {
    this.props.setIssueDescription(this.props.id, event);
  }

  render () {
    const { id, category, description } = this.props;

    return (
      <div className="cf-non-rated-issue">
        <SearchableDropdown
          name="issue-category"
          label="Issue category"
          placeholder="Select or enter..."
          options={ISSUE_CATEGORIES}
          value={category}
          onChange={(event) => this.handleCategoryChange(event)} />

        <TextField
          name="Issue description"
          value={description}
          onChange={(event) => this.handleDescriptionChange(event)} />
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
