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
      appeal
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
        confirmBox: new FormField(!this.props.displayVbmsNote),
        noteField: new FormField(vbmsNote)
      }
    };
  }

  // This is a copy of the logic from
  // AppealRepository.update_location_after_dispatch!
  // NOTE: We must keep these two methods in sync
  updatedVacolsLocationCode() {
    let specialIssues = this.props.specialIssues;

    if (specialIssues.vamc.value) {
      return "51";
    } else if (specialIssues.nationalCemeteryAdministration.value) {
      return "53";
    } else if (!this.hasSelectedSpecialIssues()) {
      return "98";
    }

    return "50";


  }

  hasSelectedSpecialIssues() {
    return Boolean(this.selectedSpecialIssues().length);
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

    return `Route Claim: Update ${noteFor.join(' and ')}`;
  }

  vacolsNoteText() {
    if (!this.hasSelectedSpecialIssues()) {
      return;
    }

    return `The BVA Full Grant decision` +
      ` dated ${formatDate(this.props.appeal.serialized_decision_date)}` +
      ` is being transfered from ARC as it contains: ` +
      `${this.selectedSpecialIssues().join(', ')} in your jurisdiction.`;
  }

  vacolsSection() {
    return <div>
      <p>To ensure this claim is routed correctly, we will take the following
      steps in VACOLS:</p>

      <ol>
        <li type="A">
          <div>
            <span className="inline-label">Change location to: </span>
            <span className="inline-value">{this.updatedVacolsLocationCode()}</span>
          </div>
        </li>
        {this.hasSelectedSpecialIssues() && <li type="A">
          <div>
            <span className="inline-label">Add the diary note: </span>
            <span className="inline-value">{this.vacolsNoteText()}</span>
          </div>
        </li>}
      </ol>
    </div>;
  }

  vbmsSection() {
    return <div>

      <p>To better route this claim, please open VBMS and
      attach the following note to the EP you just created.</p>

      <TextareaField
        label="VBMS Note:"
        name="vbmsNote"
        onChange={this.handleFieldChange('noteForm', 'noteField')}
        {...this.state.noteForm.noteField}
      />

      <div className="route-claim-confirmNote-wrapper">
        <Checkbox
          label="I confirm that I have created a VBMS note to help route this claim"
          fullWidth={true}
          name="confirmNote"
          onChange={this.handleFieldChange('noteForm', 'confirmBox')}
          {...this.state.noteForm.confirmBox}
          required={true}
        />
      </div>
    </div>;
  }

  handleSubmit = () => {
    this.props.handleSubmit(this.vacolsNoteText());
  }

  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>{this.headerText()}</h2>

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
          <ol>
            {this.props.displayVacolsNote &&
            <li className={this.props.displayVbmsNote ? 'cf-bottom-border' : ''}>
              {this.vacolsSection()}
            </li>}
            {this.props.displayVbmsNote &&
            <li>{this.vbmsSection()}</li>}
          </ol>

        </div>
        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <Button
              name="Finish Routing Claim"
              classNames={["usa-button-primary"]}
              disabled={!this.state.noteForm.confirmBox.value}
              onClick={this.handleSubmit}
            />
          </div>
        </div>
      </div>;
  }
}

EstablishClaimNote.propTypes = {
  appeal: PropTypes.object.isRequired,
  displayVacolsNote: PropTypes.bool.isRequired,
  displayVbmsNote: PropTypes.bool.isRequired,
  handleSubmit: PropTypes.func.isRequired
};
