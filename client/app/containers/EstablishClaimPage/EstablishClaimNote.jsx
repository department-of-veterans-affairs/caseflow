import React, { PropTypes } from 'react';
import BaseForm from '../BaseForm';

import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import { formatDate } from '../../util/DateUtil';
import { connect } from 'react-redux';
import SPECIAL_ISSUES from '../../constants/SpecialIssues';

export class EstablishClaimNote extends BaseForm {
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
      return "54";
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
    let result = [];
    let specialIssuesStatus = this.props.specialIssues;
    for (let key in SPECIAL_ISSUES) {
      if (specialIssuesStatus[SPECIAL_ISSUES[key].specialIssue]) {
        result.push(SPECIAL_ISSUES[key].display)
      }
    }
    return result;
  }

  headerText() {
    let noteFor = [];

    if (this.props.displayVacolsNote) {
      noteFor.push('Confirm VACOLS Update');
    }
    if (this.props.displayVbmsNote) {
      noteFor.push('Add VBMS Note');
    }

    return `Route Claim: ${noteFor.join(', ')}`;
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
      <p>To ensure this claim is routed correctly, Caseflow will make the following
      updates to VACOLS:</p>

      <ol className="cf-bold-ordered-list">
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

      <p>To help better identify this claim, please copy the following note,
      then open VBMS and attach it to the EP you just created.</p>

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
              app="dispatch"
              name="Finish routing claim"
              classNames={["usa-button-primary"]}
              disabled={!this.state.noteForm.confirmBox.value}
              onClick={this.handleSubmit}
              loading={this.props.loading}
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

/*
 * This function tells us which parts of the global
 * application state should be passed in as props to
 * the rendered component.
 */
const mapStateToProps = (state, ownProps) => {
    return {
        specialIssues: state.specialIssues
    };
};

/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const ConnectedEstablishClaimNote = connect(
    mapStateToProps,
    null,
    null
)(EstablishClaimNote);

export default ConnectedEstablishClaimNote;
