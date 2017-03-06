import React, { PropTypes } from 'react';
import BaseForm from '../BaseForm';

import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import { formatDate } from '../../util/DateUtil';

export default class EstablishClaimNote extends BaseForm {
  constructor(props) {
    super(props);
    let {
      appeal,
      specialIssues
    } = props;

    let selectedSpecialIssue = Object.keys(specialIssues).
      filter((key) => specialIssues[key].value).
      map((key) => specialIssues[key].issue);

    // Add an and if there are multiple issues so that the last element
    // in the list has an and before it.
    if (selectedSpecialIssue.length > 1) {
      selectedSpecialIssue[selectedSpecialIssue.length - 1] =
        `and ${selectedSpecialIssue[selectedSpecialIssue.length - 1]}`;
    }

    let vbmsNote = `The BVA Full Grant decision` +
      ` dated ${formatDate(appeal.serialized_decision_date)}` +
      ` for ${appeal.veteran_name}, ID #${appeal.vbms_id}, was sent to the ARC but` +
      ` cannot be processed here, as it contains ${selectedSpecialIssue.join(', ')}` +
      ` in your jurisdiction. Please proceed with control and implement this grant.`;

    let vacolsNote = `The BVA Full Grant decision` +
      ` dated ${formatDate(appeal.serialized_decision_date)}` +
      ` is being transfered from ARC as it contains: ${selectedSpecialIssue.join(', ')}` +
      ` in your jurisdiction.`;


    let noteFor = [];
    if (this.props.displayVacolsNote) {
      noteFor.push('VACOLS');
    }
    if (this.props.displayVbmsNote) {
      noteFor.push('VBMS');
    }
    let noteHeader = 'Route Claim: Update ' + noteFor.join(' and ');

    this.state = {
      noteForm: {
        confirmBox: new FormField(false),
        noteField: new FormField(vbmsNote)
      },
      noteHeader,
      vacolsNote
    };
  }

  vbmsNote() {
    return <div>
      {this.props.showNotePageAlert && <div className="usa-alert usa-alert-warning">
        <div className="usa-alert-body">
          <div>
            <h3 className="usa-alert-heading">Cannot edit end product</h3>
            <p className="usa-alert-text">
              You cannot navigate to the previous page because the end
              product has already been created and cannot be edited.
              Please proceed with adding the note below in VBMS.
            </p>
          </div>
        </div>
      </div>}

      <p>To better route this claim, please open VBMS and
      attach the following note to the EP you just created.</p>

      <TextareaField
        label="VBMS Note"
        name="vbmsNote"
        onChange={this.handleFieldChange('noteForm', 'noteField')}
        {...this.state.noteForm.noteField}
      />

      <Checkbox
        label="I confirm that I have created a VBMS note to help route this claim"
        name="confirmNote"
        onChange={this.handleFieldChange('noteForm', 'confirmBox')}
        {...this.state.noteForm.confirmBox}
      />
    </div>;
  }

  vacolsNote() {
    return <div>
      <p>To ensure this claim is routed correctly, we will take the following
      steps in VACOLS:</p>

      <p>A. Change location to: [location code]</p>
      <p>B. Add the diary note: {this.state.vacolsNote}</p>
      <p>C. Change the ROJ to: [ROJ]</p>
    </div>;
  }

  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>{this.state.noteHeader}</h2>
          
          <ol>
            {this.props.displayVacolsNote &&
            <li className={this.props.displayVbmsNote ? 'cf-bottom-border' : ''}>
              {this.vacolsNote()}
            </li>}  
            {this.props.displayVbmsNote &&
            <li>{this.vbmsNote()}</li>}
          </ol>

        </div>
        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <Button
              name="Finish Routing Claim"
              classNames={["usa-button-primary"]}
              disabled={!this.state.noteForm.confirmBox.value}
              onClick={this.props.handleSubmit}
            />
          </div>
        </div>
      </div>;
  }
}

EstablishClaimNote.propTypes = {
  appeal: PropTypes.object.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  displayVacolsNote: PropTypes.bool.isRequired,
  displayVbmsNote: PropTypes.bool.isRequired
};
