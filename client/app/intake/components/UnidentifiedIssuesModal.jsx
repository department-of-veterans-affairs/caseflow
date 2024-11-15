import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import TextField from '../../components/TextField';
import DateSelector from '../../components/DateSelector';
import { validateDateNotInFuture, isTimely } from '../util/issues';
import Checkbox from '../../components/Checkbox';
import { generateSkipButton } from '../util/buttonUtils';
import Alert from 'app/components/Alert';
import { VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER } from 'app/../COPY';

class UnidentifiedIssuesModal extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      description: '',
      notes: '',
      verifiedUnidentifiedIssue: false,
      userIsVhaAdmin: props.intakeData.userIsVhaAdmin,
      isTaskInProgress: props.intakeData.taskInProgress,
      benefitType: props.intakeData.benefitType
    };
  }

  vhaHlrOrSC() {
    const { benefitType } = this.state;
    const { formType } = this.props;

    return ((formType === 'higher_level_review' || formType === 'supplemental_claim') && benefitType === 'vha');
  }

  // default mst and pact to false for Unidentified issues
  onAddIssue = () => {
    const { description, notes, decisionDate, verifiedUnidentifiedIssue } = this.state;
    const { formType, intakeData } = this.props;
    const currentIssue = {
      isUnidentified: !verifiedUnidentifiedIssue,
      description,
      notes,
      decisionDate,
      verifiedUnidentifiedIssue,
      mstChecked: false,
      pactChecked: false,
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
      description: value
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
    if (typeof (value) === 'undefined') {
      return null;
    }
    if (value.length === 10) {
      const error = validateDateNotInFuture(value) ? null : 'Decision date cannot be in the future.';

      return error;
    }
  };

  onCheckboxChange = (event) => {
    this.setState({ verifiedUnidentifiedIssue: event });
  };

  saveDisabled = () => {

    const descriptionIsValid = this.isDescriptionValid(this.state.description);
    const decisionDateIsValid = Boolean(this.state.decisionDate) && !this.errorOnDecisionDate(this.state.decisionDate);
    const isDecisionDateRequired = this.vhaHlrOrSC() && this.state.userIsVhaAdmin && this.state.isTaskInProgress;
    const notes = this.state.notes;

    if (this.state.verifiedUnidentifiedIssue) {
      return !(descriptionIsValid && decisionDateIsValid && notes);
    }

    // if Decision date is not required then we need to verify if there is any error in the decision date field
    // this.errorOnDecisionDate returns null if no error is present.
    return isDecisionDateRequired ?
      !(descriptionIsValid && decisionDateIsValid) :
      !(descriptionIsValid && !this.errorOnDecisionDate(this.state.decisionDate));
  }

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
        disabled: this.saveDisabled()
      }
    ];

    generateSkipButton(btns, this.props);

    return btns;
  }

  getDecisionDate() {
    const { decisionDate, userIsVhaAdmin, isTaskInProgress } = this.state;

    return (
      <React.Fragment>
        {(userIsVhaAdmin && isTaskInProgress && this.vhaHlrOrSC()) ?
          <Alert
            message={VHA_ADMIN_DECISION_DATE_REQUIRED_BANNER}
            type="info"
          /> :
          null
        }
        <div className="decision-date" style={{ marginTop: '20px' }}>
          <DateSelector
            name="decision-date"
            label="Decision date"
            strongLabel
            value={decisionDate}
            errorMessage={this.state.dateError}
            onChange={this.decisionDateOnChange}
            type="date"
            optional={
              !this.state.verifiedUnidentifiedIssue &&
              !(userIsVhaAdmin && isTaskInProgress &&
                this.vhaHlrOrSC())
            }
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
        <p>If found, please check below that it is verified. Use the prior decision's information
        to enter the description and decision date. Update the notes with information on the record,
        such as the location, ID, or document title.
        </p>
        <Checkbox
          label={<strong>Verify record of prior decision</strong>}
          name="verify_prior_record"
          value={this.state.verifiedUnidentifiedIssue}
          onChange={this.onCheckboxChange}
        />
      </React.Fragment>
    );
  }

  render() {
    const { intakeData, onCancel } = this.props;

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
          {this.getDecisionDate()}
          <TextField name="Notes"
            optional={!this.state.verifiedUnidentifiedIssue}
            strongLabel
            value={this.state.notes}
            onChange={this.onNotesChange} />
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
  editPage: PropTypes.bool,
  userIsVhaAdmin: PropTypes.bool,
  isTaskInProgress: PropTypes.bool,
};

UnidentifiedIssuesModal.defaultProps = {
  submitText: 'Add this issue',
  cancelText: 'Cancel adding this issue',
  skipText: 'None of these match, see more options'
};

export default UnidentifiedIssuesModal;
