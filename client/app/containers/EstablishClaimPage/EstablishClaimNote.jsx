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

    this.state = {
      noteForm: {
        confirmBox: new FormField(false),
        noteField: new FormField(this.props.note)
      }
    };
  }

  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Route Claim</h2>
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
  note: PropTypes.string.isRequired,
  handleSubmit: PropTypes.func.isRequired
};
