import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import { validateDateNotInFuture } from '../util/issues';

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
    const currentIssue = {
      isUnidentified: true,
      description,
      notes,
      decisionDate
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

  render() {
    const { intakeData, onCancel, featureToggles } = this.props;
    const { unidentifiedIssueDecisionDate } = featureToggles;

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
  intakeData: PropTypes.object
};

UnidentifiedIssuesModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default UnidentifiedIssuesModal;
