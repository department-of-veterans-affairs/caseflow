import React, { PropTypes } from 'react';
import BaseForm from '../BaseForm';

import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import { formatDate } from '../../util/DateUtil';
import requiredValidator from '../../util/validators/RequiredValidator';

export default class EstablishClaimDiary extends BaseForm {
  constructor(props) {
    super(props);

    this.state = {
      diaryForm: {
        diaryField: new FormField(
          this.props.note,
          requiredValidator('Please enter a diary note'))
      }
    };
  }

  render() {
    return <div>
        <div className="cf-app-segment cf-app-segment--alt">
          <h2>Route Claim</h2>
          <div className="usa-alert usa-alert-info">
            <div className="usa-alert-body">
              <div>
                <h3 className="usa-alert-heading">We are unable to create an
                  EP for claims with this Special Issue</h3>
              </div>
            </div>
          </div>
          <p>To ensure this claim is routed correctly, we will take
            the following steps in VACOLS.</p>
          <p><b>1.</b> Change the location code to {this.props.locationCode}</p>

          <TextareaField
            label={<span><b>2.</b> Add the diary note:</span>}
            name="emailMessage"
            onChange={this.handleFieldChange('diaryForm', 'diaryField')}
            {...this.state.diaryForm.diaryField}
          />
          <p><b>3.</b> Change the ROJ to {this.props.regionalOffice}</p>
        </div>

        <div className="cf-app-segment" id="establish-claim-buttons">
          <div className="cf-push-right">
            <Button
                name="Cancel"
                onClick={this.props.handleCancelTask}
                classNames={["cf-btn-link", "cf-adjacent-buttons"]}
            />
            <Button
                name="Finish Routing Claim"
                classNames={["usa-button-primary"]}
                onClick={this.props.handleSubmit}
            />
          </div>
        </div>
      </div>;
  }
}

EstablishClaimDiary.propTypes = {
  note: PropTypes.string.isRequired,
  handleCancelTask: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  regionalOffice: PropTypes.string.isRequired,
  locationCode: PropTypes.string.isRequired
};
