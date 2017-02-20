import React, { PropTypes } from 'react';
import BaseForm from '../BaseForm';

import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import { formatDate } from '../../util/DateUtil';

export const VBMS_NOTE = 'vbms';
export const VACOLS_NOTE = 'vacols';

export default class EstablishClaimEmail extends BaseForm {
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

    let note = `The BVA Full Grant decision dated ${formatDate(appeal.decision_date)}` +
      ` for ${appeal.veteran_name}, ID #${appeal.vbms_id}, was sent to the ARC but` +
      ` cannot be processed here, as it contains ${selectedSpecialIssue.join(', ')}` +
      ` in your jurisdiction. Please proceed with control and implement this grant.`;

    this.state = {
      noteForm: {
        confirmBox: new FormField(false),
        noteField: new FormField(note)
      }
    };
  }

  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Route Claim</h2>
          <div>
            <div className="usa-alert usa-alert-info">
              <div className="usa-alert-body">
                <div>
                  <h3 className="usa-alert-heading">We are unable to create an
                    EP for claims with this Special Issue</h3>
                  <p className="usa-alert-text">
                    Follow the instructions below to route this claim.
                  </p>
                </div>
              </div>
            </div>
            <p>Please send the following email message to the office
            responsible for implementing this grant.</p>
            <p><b>RO:</b> {this.props.regionalOffice}</p>
            <p><b>RO email:</b> {this.props.regionalOfficeEmail.join(',')}</p>
          </div>

          <TextareaField
            label={<b>Message</b>}
            required={true}
            name="emailMessage"
            onChange={this.handleFieldChange('noteForm', 'noteField')}
            {...this.state.noteForm.noteField}
          />

          <Checkbox
            label="I confirm that I have sent an email to route this claim."
            name="confirmNote"
            onChange={this.handleFieldChange('noteForm', 'confirmBox')}
            {...this.state.noteForm.confirmBox}
          />

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

EstablishClaimEmail.propTypes = {
  appeal: PropTypes.object.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  regionalOffice: PropTypes.string.isRequired,
  regionalOfficeEmail: PropTypes.arrayOf(PropTypes.string).isRequired
};
