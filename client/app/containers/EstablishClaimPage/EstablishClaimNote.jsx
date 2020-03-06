import React from 'react';
import PropTypes from 'prop-types';
import BaseForm from '../BaseForm';

import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import { formatDateStr } from '../../util/DateUtil';
import { connect } from 'react-redux';
import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import CopyToClipboard from 'react-copy-to-clipboard';
import _ from 'lodash';

export class EstablishClaimNote extends BaseForm {
  constructor(props) {
    super(props);
    let { appeal } = props;

    // Add an and if there are multiple issues so that the last element
    // in the list has an and before it.
    let selectedSpecialIssues = this.selectedSpecialIssues();

    if (selectedSpecialIssues.length > 1) {
      selectedSpecialIssues[selectedSpecialIssues.length - 1] = `and ${
        selectedSpecialIssues[selectedSpecialIssues.length - 1]
      }`;
    }

    let vbmsNote =
      `The BVA ${this.props.decisionType} decision` +
      ` dated ${formatDateStr(appeal.serialized_decision_date)}` +
      ` for ${appeal.veteran_name}, ID #${appeal.vbms_id}, was sent to the ARC but` +
      ` cannot be processed here, as it contains ${selectedSpecialIssues.join(', ')}` +
      ' in your jurisdiction. Please proceed with control and implement this grant.';

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

    if (specialIssues.vamc) {
      return '54';
    } else if (specialIssues.nationalCemeteryAdministration) {
      return '53';
    } else if (!this.hasSelectedSpecialIssues()) {
      return '98';
    }

    return '50';
  }

  hasSelectedSpecialIssues() {
    return Boolean(this.selectedSpecialIssues().length);
  }

  selectedSpecialIssues() {
    return _.reduce(
      SPECIAL_ISSUES,
      (result, issue) => {
        if (this.props.specialIssues[issue.specialIssue]) {
          result.push(issue.display);
        }

        return result;
      },
      []
    );
  }

  headerVacols() {
    if (this.props.displayVacolsNote) {
      return 'Confirm VACOLS Update';
    }
  }

  headerVbms() {
    if (this.props.displayVbmsNote) {
      return 'Add VBMS Note';
    }
  }

  vacolsNoteText() {
    if (!this.hasSelectedSpecialIssues()) {
      return;
    }

    return (
      `The BVA ${this.props.decisionType} decision` +
      ` dated ${formatDateStr(this.props.appeal.serialized_decision_date)}` +
      ' is being transfered from ARC as it contains: ' +
      `${this.selectedSpecialIssues().join(', ')} in your jurisdiction.`
    );
  }

  vacolsSection() {
    return (
      <div>
        <p>To ensure this claim is routed correctly, Caseflow will make the following updates to VACOLS:</p>

        <ol>
          <li type="A">
            <div>
              <span className="inline-label">Change location to: </span>
              <span className="inline-value">{this.updatedVacolsLocationCode()}</span>
            </div>
          </li>
          {this.hasSelectedSpecialIssues() && (
            <li type="A">
              <div>
                <span className="inline-label">Add the diary note: </span>
                <span className="inline-value">{this.vacolsNoteText()}</span>
              </div>
            </li>
          )}
        </ol>
      </div>
    );
  }

  vbmsSection() {
    return (
      <div>
        <p>
          To help better identify this claim, please copy the following note, then open VBMS and attach it to the EP you
          just created.
        </p>

        <div className="cf-vbms-note">
          <TextareaField
            label="VBMS Note:"
            name="vbmsNote"
            onChange={this.handleFieldChange('noteForm', 'noteField')}
            {...this.state.noteForm.noteField}
          />

          <div className="cf-app-segment copy-note-button">
            <div className="cf-push-left">
              <CopyToClipboard text={this.state.noteForm.noteField.value}>
                <Button label="Copy note" name="copyNote" classNames={['usa-button-secondary usa-button-hover']}>
                  <i className="fa fa-files-o" aria-hidden="true" />
                  Copy note
                </Button>
              </CopyToClipboard>
            </div>
          </div>
        </div>

        <div className="route-claim-confirmNote-wrapper">
          <Checkbox
            label="I confirm that I have created a VBMS note to help route this claim."
            name="confirmNote"
            onChange={this.handleFieldChange('noteForm', 'confirmBox')}
            {...this.state.noteForm.confirmBox}
            required
          />
        </div>
      </div>
    );
  }

  handleSubmit = () => {
    this.props.handleSubmit(this.vacolsNoteText());
  };

  render() {
    return (
      <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Route Claim</h1>
          <h2>{this.headerVacols()}</h2>

          {this.props.showNotePageAlert && (
            <Alert title="Cannot edit end product" type="warning">
              You cannot navigate to the previous page because the end product has already been created and cannot be
              edited. Please proceed with adding the note below in VBMS.
            </Alert>
          )}

          <ol className="cf-bold-ordered-list">
            {this.props.displayVacolsNote && <li>{this.vacolsSection()}</li>}
          </ol>
          {this.props.displayVacolsNote && this.props.displayVbmsNote && <div className="cf-bottom-border" />}
          <h2>{this.headerVbms()}</h2>
          <ol start={this.props.displayVacolsNote ? '2' : ''} className="cf-bold-ordered-list">
            {this.props.displayVbmsNote && <li>{this.vbmsSection()}</li>}
          </ol>
        </div>
        <div className="cf-app-segment" id="establish-claim-buttons">
          {!this.props.endProductCreated && (
            <div className="cf-push-left">
              <Button
                name={this.props.backToDecisionReviewText}
                onClick={this.props.handleBackToDecisionReview}
                classNames={['cf-btn-link']}
              />
            </div>
          )}
          <div className="cf-push-right">
            <Button
              app="dispatch"
              name="Finish routing claim"
              classNames={['usa-button-primary']}
              disabled={!this.state.noteForm.confirmBox.value}
              onClick={this.handleSubmit}
              loading={this.props.loading}
            />
          </div>
        </div>
      </div>
    );
  }
}

EstablishClaimNote.propTypes = {
  appeal: PropTypes.object.isRequired,
  displayVacolsNote: PropTypes.bool.isRequired,
  displayVbmsNote: PropTypes.bool.isRequired,
  handleSubmit: PropTypes.func.isRequired
};

const mapStateToProps = (state) => {
  return {
    specialIssues: state.specialIssues
  };
};

const ConnectedEstablishClaimNote = connect(mapStateToProps)(EstablishClaimNote);

export default ConnectedEstablishClaimNote;
