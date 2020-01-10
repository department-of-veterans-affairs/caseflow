import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import { validateDateNotInFuture, isTimely } from '../util/issues';
import Checkbox from '../../components/Checkbox';

class UnidentifiedIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      description: '',
      notes: '',
      disabled: true
    };
  }

  onAddIssue = () => {
    const { description, notes, decisionDate } = this.state;
    const { formType, intakeData } = this.props;
    const currentIssue = {
      isUnidentified: true,
      description,
      notes,
      decisionDate,
      timely: isTimely(formType, decisionDate, intakeData.receiptDate)
    };

    this.props.onSubmit({ currentIssue });
  };

  isDescriptionValid = (description) => {
    // make sure description has some characters in it
    return (/[a-zA-Z]+/).test(description);
  };

  onDescriptionChange = (value) => {
    this.setState({
      description: value,
      disabled: !this.isDescriptionValid(value)
    });
  };

  onNotesChange = (value) => {
    this.setState({
      notes: value
    });
  };

  decisionDateOnChange = (value) => {
    this.setState({
      decisionDate: value,
      dateError: this.errorOnDecisionDate(value)
    });
  };

  errorOnDecisionDate = (value) => {
    if (value.length === 10) {
      const error = validateDateNotInFuture(value) ? null : 'Decision date cannot be in the future.';

      return error;
    }
  };

  onCheckboxChange = (value) => {
    this.setState({ checkboxSelected: value });
  };

  isCheckboxChecked = () => {
    return this.state.checkboxSelected;
  };

  getModalButtons() {
    const btns = [
      {
        classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
        name: this.props.cancelText,
        onClick: this.props.onCancel
      },
      {
        classNames: ['usa-button', 'add-issue'],
        name: this.props.submitText,
        onClick: this.onAddIssue,
        disabled: this.state.disabled
      }
    ];

    if (this.props.onSkip) {
      btns.push({
        classNames: ['usa-button', 'usa-button-secondary', 'no-matching-issues'],
        name: this.props.skipText,
        onClick: this.props.onSkip
      });
    }

    return btns;
  }

  getDecisionDate() {
    const { decisionDate } = this.state;

    return (
      <React.Fragment>
        <div className="decision-date">
          <DateSelector
            name="decision-date"
            label="Decision date"
            strongLabel
            value={decisionDate}
            errorMessage={this.state.dateError}
            onChange={this.decisionDateOnChange}
            type="date"
            optional
          />
        </div>

      </React.Fragment>
    );
  }

  getCheckbox() {
    return (
      <React.Fragment>
        <p>Please look for a record of the prior decision matching the description
    and decision date of the issue that was submitted by the veteran.</p>
        <br />
        <p>If you were unable to find a record of the prior decision,
    please leave the checkbox unchecked and fill in the description
    and decision date submitted by the veteran. </p>
        <br />
        <p>If found, please check below that it is verified. Use the prior decision's information
        to enter the description and decision date. Update the notes with information on the record,
        such as the location, ID, or document title.
        </p>
        <Checkbox
          label={<strong>Verify record of prior decision</strong>}
          name="verify_prior_record"
          value={this.isCheckboxChecked()}
          onChange={this.onCheckboxChange}
        />
      </React.Fragment>
    );
  }

  render() {
    const { intakeData, onCancel, featureToggles, editPage } = this.props;
    const { unidentifiedIssueDecisionDate, verifyUnidentifiedIssue } = featureToggles;

    const issueNumber = (intakeData.addedIssues || []).length + 1;

    return (
      <div className="intake-add-issues">
        <Modal buttons={this.getModalButtons()} visible closeHandler={onCancel} title={`Add issue ${issueNumber}`}>
          <h2>Describe the issue to mark it as needing further review.</h2>
          <TextField
            name="Transcribe the issue as it's written on the form"
            strongLabel
            value={this.state.description}
            onChange={this.onDescriptionChange}
          />
          {unidentifiedIssueDecisionDate && this.getDecisionDate()}
          <TextField name="Notes" optional strongLabel value={this.state.notes} onChange={this.onNotesChange} />
          {editPage && verifyUnidentifiedIssue && this.getCheckbox()}
        </Modal>
      </div>
    );
  }
}

UnidentifiedIssuesModal.propTypes = {
  onSubmit: PropTypes.func,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  skipText: PropTypes.string,
  featureToggles: PropTypes.object,
  intakeData: PropTypes.object,
  formType: PropTypes.string,
  editPage: PropTypes.bool
};

UnidentifiedIssuesModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default UnidentifiedIssuesModal;
