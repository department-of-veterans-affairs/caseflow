import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { addRatingRequestIssue, addNonratingRequestIssue } from '../actions/addIssues';

class UntimelyExemptionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      untimelyExemption: '',
      untimelyExemptionNotes: ''
    };
  }

  onAddIssue = () => {
    const currentIssueData = this.props.intakeData.currentIssueAndNotes
    const currentIssue = currentIssueData.currentIssue;

    if (currentIssue.reference_id) {
      this.props.addRatingRequestIssue({
        timely: false,
        issueId: currentIssue.reference_id,
        ratings: this.props.intakeData.ratings,
        isRating: true,
        notes: currentIssueData.notes,
        legacyIssueId: currentIssueData.legacyIssueId,
        vacolsSequenceId: currentIssueData.vacolsSequenceId,
        untimelyExemption: this.state.untimelyExemption,
        untimelyExemptionNotes: this.state.untimelyExemptionNotes
      });
    } else {
      this.props.addNonratingRequestIssue({
        timely: false,
        isRating: false,
        untimelyExemption: this.state.untimelyExemption,
        untimelyExemptionNotes: this.state.untimelyExemptionNotes,
        category: currentIssue.category,
        description: currentIssue.description,
        decisionDate: currentIssue.decisionDate,
        legacyIssueId: currentIssueData.legacyIssueId,
        vacolsSequenceId: currentIssueData.vacolsSequenceId,
      });
    }
    this.props.closeHandler();
  }

  radioOnChange = (value) => {
    this.setState({
      untimelyExemption: value
    });
  }

  untimelyExemptionNotesOnChange = (value) => {
    this.setState({
      untimelyExemptionNotes: value
    });
  }

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const issueNumber = (intakeData.addedIssues || []).length + 1;
    const issue = intakeData.currentIssueAndNotes.currentIssue;

    return <div className="intake-add-issues">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'add-issue'],
            name: 'Add this issue',
            onClick: this.onAddIssue,
            disabled: this.state.disabled
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`Issue ${issueNumber} is an Untimely Issue`}
      >
        <p><strong>Requested issue:</strong> {issue.description}</p>
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
        <TextField
          name="Notes"
          optional
          strongLabel
          value={this.state.untimelyExemptionNotes}
          onChange={this.untimelyExemptionNotesOnChange}
        />
      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addRatingRequestIssue,
    addNonratingRequestIssue
  }, dispatch)
)(UntimelyExemptionModal);
