import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';

class UntimelyExemptionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      untimelyExemption: '',
      untimelyExemptionNotes: ''
    };
  }

  onAddIssue = () => {
    const { untimelyExemption, untimelyExemptionNotes } = this.state;

    this.props.onSubmit({ untimelyExemption,
      untimelyExemptionNotes });
  };

  radioOnChange = (value) => {
    this.setState({
      untimelyExemption: value
    });
  };

  untimelyExemptionNotesOnChange = (value) => {
    this.setState({
      untimelyExemptionNotes: value
    });
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
        disabled: !this.state.untimelyExemption
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

  render() {
    const { intakeData, onCancel, currentIssue } = this.props;

    const issueNumber = (intakeData.addedIssues || []).length + 1;
    // const issue = intakeData.currentIssueAndNotes.currentIssue;
    const issue = currentIssue;

    return (
      <div className="intake-add-issues">
        <Modal
          buttons={this.getModalButtons()}
          visible
          closeHandler={onCancel}
          title={`Issue ${issueNumber} is an Untimely Issue`}
        >
          <p>
            <strong>Requested issue:</strong> {issue.description}
          </p>
          <p>The issue requested isn't usually eligible because its decision date is older than what's allowed.</p>
          <RadioField
            name="untimely-exemption"
            label="Did the applicant request an extension to the date requirements?"
            strongLabel
            vertical
            options={BOOLEAN_RADIO_OPTIONS}
            onChange={this.radioOnChange}
            value={this.state.untimelyExemption === null ? null : this.state.untimelyExemption.toString()}
          />

          {this.state.untimelyExemption === 'true' && (
            <TextField
              name="Notes"
              optional
              strongLabel
              value={this.state.untimelyExemptionNotes}
              onChange={this.untimelyExemptionNotesOnChange}
            />
          )}
        </Modal>
      </div>
    );
  }
}

UntimelyExemptionModal.propTypes = {
  onSubmit: PropTypes.func,
  submitText: PropTypes.string,
  onCancel: PropTypes.func,
  cancelText: PropTypes.string,
  onSkip: PropTypes.func,
  skipText: PropTypes.string
};

UntimelyExemptionModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default UntimelyExemptionModal;
