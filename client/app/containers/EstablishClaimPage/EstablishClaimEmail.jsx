import React, { PropTypes } from 'react';
import BaseForm from '../BaseForm';

import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import FormField from '../../util/FormField';
import { formatDate } from '../../util/DateUtil';

export default class EstablishClaimEmail extends BaseForm {
  constructor(props) {
    super(props);

    this.state = {
      emailForm: {
        confirmBox: new FormField(false),
        emailField: new FormField(this.props.note)
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
            label="Message"
            required={true}
            name="emailMessage"
            onChange={this.handleFieldChange('emailForm', 'emailField')}
            {...this.state.emailForm.emailField}
          />

          <Checkbox
            label="I confirm that I have sent an email to route this claim."
            name="confirmEmail"
            onChange={this.handleFieldChange('emailForm', 'confirmBox')}
            {...this.state.emailForm.confirmBox}
          />

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
                disabled={!this.state.emailForm.confirmBox.value}
                onClick={this.props.handleSubmit}
            />
          </div>
        </div>
      </div>;
  }
}

EstablishClaimEmail.propTypes = {
  note: PropTypes.string.isRequired,
  handleCancelTask: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  regionalOffice: PropTypes.string.isRequired,
  regionalOfficeEmail: PropTypes.arrayOf(PropTypes.string).isRequired
};
