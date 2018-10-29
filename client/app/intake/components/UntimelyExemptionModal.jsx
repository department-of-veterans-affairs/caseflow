import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import React from 'react';

import Modal from '../../components/Modal';
import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { addRatedIssue } from '../actions/addIssues';

class UntimelyExemptionModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      untimelyExemption: '',
      untimelyExemptionNotes: ''
    };
  }

  onAddIssue = () => {
    this.props.addRatedIssue({
      issueId: this.props.referenceId,
      ratings: this.props.intakeData.ratings,
      isRated: true,
      notes: this.props.notes,
      untimelyExemption: this.state.untimelyExemption,
      untimelyExemptionNotes: this.state.untimelyExemptionNotes
    });
    this.props.closeHandler();
  }

  radioOnChange = (value) => {
    this.setState({
      untimelyExemption: value
    });
  }

  untimelyExemptionNotesOnChange = (value) => {
    this.setState({
      notes: value
    });
  }

  render() {
    let {
      intakeData,
      closeHandler
    } = this.props;

    const issueNumber = (intakeData.addedIssues || []).length + 1;

    return <div className="intake-add-issues">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel adding this issue',
            onClick: closeHandler
          },
          { classNames: ['usa-button', 'usa-button-secondary', 'add-issue'],
            name: 'Add this issue',
            onClick: this.onAddIssue,
            disabled: this.state.disabled
          }
        ]}
        visible
        closeHandler={closeHandler}
        title={`${issueNumber} is an Untimely Issue`}
      >
        <p><strong>Requested issue:</strong> {issue.description}</p>
        <p>The issue requested isn't usually eligible because its decision date is older than what's allowed.</p>
        <RadioField
          name="untimely-exemption"
          label="Did the applicant request an exemption to the date requirements?"
          strongLabel
          vertical
          options={BOOLEAN_RADIO_OPTIONS}
          onChange={this.radioOnChange}
          value={untimelyExemption === null ? null : untimelyExemption.toString()}
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
    addRatedIssue
  }, dispatch)
)(UntimelyExemptionModal);
