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

    // Add an and if there are multiple issues so that the last element
    // in the list has an and before it.
    let selectedSpecialIssues = this.selectedSpecialIssues();

    if (selectedSpecialIssues.length > 1) {
      selectedSpecialIssues[selectedSpecialIssues.length - 1] =
        `and ${selectedSpecialIssues[selectedSpecialIssues.length - 1]}`;
    }

    let vbmsNote = `The BVA Full Grant decision` +
      ` dated ${formatDate(appeal.serialized_decision_date)}` +
      ` for ${appeal.veteran_name}, ID #${appeal.vbms_id}, was sent to the ARC but` +
      ` cannot be processed here, as it contains ${selectedSpecialIssues.join(', ')}` +
      ` in your jurisdiction. Please proceed with control and implement this grant.`;


    this.state = {
      noteForm: {
        confirmBox: new FormField(false),
        noteField: new FormField(vbmsNote)
      }
    };
  }

  // This is a copy of the logic from
  // AppealRepository.update_location_after_dispatch!
  // NOTE: We must keep these two methods in sync
  updatedVacolsLocationCode() {
    let specialIssues = this.props.specialIssues;
    let station = this.props.stationofJurisdiction;

    if (specialIssues.vamc.value) {
      return "51";
    } else if (specialIssues.nationalCemeteryAdministration.value) {
      return "53";
    } else if (station === "397" && !this.hasSelectedSpecialIssues()) {
      return "98";
    } else if (station !== "397" && this.hasSelectedSpecialIssues()) {
      return "50";
    } else {
      return "N/A";
    }
  }

  hasSelectedSpecialIssues() {
    return this.selectedSpecialIssues().length;
  }

  selectedSpecialIssues() {
    let specialIssues = this.props.specialIssues;

    return Object.keys(specialIssues).
      filter((key) => specialIssues[key].value).
      map((key) => specialIssues[key].issue);
  }

  headerText() {
    let noteFor = [];
    if (this.props.displayVacolsNote) {
      noteFor.push('VACOLS');
    }
    if (this.props.displayVbmsNote) {
      noteFor.push('VBMS');
    }

    return 'Route Claim: Update ' + noteFor.join(' and ');
  }

  vacolsNoteText() {
    return `The BVA Full Grant decision` +
      ` dated ${formatDate(this.props.appeal.serialized_decision_date)}` +
      ` is being transfered from ARC as it contains: ${this.selectedSpecialIssues().join(', ')}` +
      ` in your jurisdiction.`;
  }

  vacolsNote() {
    return <div>
      <p>To ensure this claim is routed correctly, we will take the following
      steps in VACOLS:</p>

      <p>
        <span>A. Change location to: </span><span>{this.updatedVacolsLocationCode()}</span>
      </p>
      <p>
        <span>B. Add the diary note: </span><span>{this.vacolsNoteText()}</span>
      </p>
    </div>;
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
        required={true}
      />
    </div>;
  }


  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>{this.headerText()}</h2>
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
