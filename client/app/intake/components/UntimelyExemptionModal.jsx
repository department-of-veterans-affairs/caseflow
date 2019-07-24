import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { addContestableIssue, addNonratingRequestIssue } from '../actions/addIssues';
import { isCorrection } from '../util';

class UntimelyExemptionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      untimelyExemption: '',
      untimelyExemptionNotes: ''
    };
  }

  onAddIssue = () => {
    const currentIssueData = this.props.intakeData.currentIssueAndNotes;
    const currentIssue = currentIssueData.currentIssue;

    if (currentIssue.category) {
      this.props.addNonratingRequestIssue({
        timely: false,
        isRating: false,
        untimelyExemption: this.state.untimelyExemption,
        untimelyExemptionNotes: this.state.untimelyExemptionNotes,
        benefitType: currentIssue.benefitType,
        category: currentIssue.category,
        description: currentIssue.description,
        decisionDate: currentIssue.decisionDate,
        vacolsId: currentIssueData.vacolsId,
        vacolsSequenceId: currentIssueData.vacolsSequenceId,
        eligibleForSocOptIn: currentIssueData.eligibleForSocOptIn,
        correctionType: isCorrection(false, this.props.intakeData) ? 'control' : null
      });
    } else {
      this.props.addContestableIssue({
        timely: false,
        contestableIssueIndex: currentIssue.index,
        contestableIssues: this.props.intakeData.contestableIssues,
        isRating: currentIssue.isRating,
        notes: currentIssueData.notes,
        untimelyExemption: this.state.untimelyExemption,
        untimelyExemptionNotes: this.state.untimelyExemptionNotes,
        vacolsId: currentIssueData.vacolsId,
        vacolsSequenceId: currentIssueData.vacolsSequenceId,
        eligibleForSocOptIn: currentIssueData.eligibleForSocOptIn,
        correctionType: isCorrection(currentIssue.isRating, this.props.intakeData) ? 'control' : null
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

        {
          this.state.untimelyExemption === 'true' && <TextField
            name="Notes"
            optional
            strongLabel
            value={this.state.untimelyExemptionNotes}
            onChange={this.untimelyExemptionNotesOnChange}
          />
        }

      </Modal>
    </div>;
  }
}

export default connect(
  null,
  (dispatch) => bindActionCreators({
    addContestableIssue,
    addNonratingRequestIssue
  }, dispatch)
)(UntimelyExemptionModal);
