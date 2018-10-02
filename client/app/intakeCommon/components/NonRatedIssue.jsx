import React from 'react';
import SearchableDropdown from '../../components/SearchableDropdown';
import TextField from '../../components/TextField';
import Button from '../../components/Button';
import DateSelector from '../../components/DateSelector';
import { ISSUE_CATEGORIES } from '../constants';
import _ from 'lodash';

export default class NonRatedIssue extends React.PureComponent {
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
    const {
      issueId, // issue?
      category,
      description,
      decisionDate,
      nonRatedIssues,
      addNonRatedIssue,
      setIssueCategory,
      setIssueDescription,
      setIssueDecisionDate
    } = this.props;

    return (
      <div>
        <h2>
          Does this issue match any of these issue categories?
        </h2>

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

      <Button
        name="add-issue"
        onClick={addNonRatedIssue}
        classNames={['usa-button-secondary']}
        disabled={disableAddNonRatedIssue}
      >
        + Add issue
      </Button>
    );
  }
}
