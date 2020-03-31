import React from 'react';
import PropTypes from 'prop-types';

import BaseForm from '../BaseForm';
import ApiUtil from '../../util/ApiUtil';

import WindowUtil from '../../util/WindowUtil';
import Checkbox from '../../components/Checkbox';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import Alert from '../../components/Alert';
import FormField from '../../util/FormField';
import { formatDateStr } from '../../util/DateUtil';
import { connect } from 'react-redux';
import CopyToClipboard from 'react-copy-to-clipboard';
import { enabledSpecialIssues } from '../../constants/SpecialIssueEnabler.js';
import * as Constants from '../../establishClaim/constants';
import { getSpecialIssuesRegionalOfficeCode } from '../../establishClaim/util';

export class EstablishClaimEmail extends BaseForm {
  constructor(props) {
    super(props);
    let {
      appeal
    } = props;

    let specialIssuesStatus = this.props.specialIssues;

    const selectedSpecialIssue = enabledSpecialIssues(this.props.featureToggles.special_issues_revamp).map((issue) => {
      if (specialIssuesStatus[issue.specialIssue]) {
        return issue.display
      }
    })

    // Add an and if there are multiple issues so that the last element
    // in the list has an and before it.
    if (selectedSpecialIssue.length > 1) {
      selectedSpecialIssue[selectedSpecialIssue.length - 1] =
        `and ${selectedSpecialIssue[selectedSpecialIssue.length - 1]}`;
    }

    let email = 'The BVA Full Grant decision dated' +
      ` ${formatDateStr(appeal.serialized_decision_date)}` +
      ` for ${appeal.veteran_name},` +
      ` ID #${appeal.sanitized_vbms_id}, was sent to the ARC but` +
      ` cannot be processed here, as it contains ${selectedSpecialIssue.join(', ')}` +
      ' in your jurisdiction. Please proceed with control and implement this grant.';

    this.state = {
      emailForm: {
        confirmBox: new FormField(false),
        emailField: new FormField(email)
      }
    };
  }

  // For Each Regional Office Mailto Link
  renderRegionalOfficeEmaillist() {
    return this.props.regionalOfficeEmail.map((regionalOfficeEmailMailto, index, arr) => {
      return (
        <a key={regionalOfficeEmailMailto} href={`mailto:${regionalOfficeEmailMailto}`}>
          {regionalOfficeEmailMailto}{index === arr.length - 1 ? '' : '; '}
        </a>
      );
    });
  }

  render() {
    return <div>
      { this.props.regionalOfficeEmail &&
        <div>
          <div className="cf-app-segment cf-app-segment--alt">
            <h1>Route Claim</h1>
            <h2>Send Email Notification</h2>
            <div className="cf-email-header">
              <Alert
                title="We are unable to create an
                EP for claims with this Special Issue"
                type="info">
              Follow the instructions below to route this claim.
              </Alert>
              <p>Please send the following email message to the office
              responsible for implementing this grant.</p>
              <aside>
                <p><b>RO:</b> {this.props.regionalOffice}</p>
                <p><b>RO email:</b> {this.renderRegionalOfficeEmaillist()}</p>
              </aside>
            </div>

            <div className ="cf-vbms-note">
              <TextareaField
                label="Message:"
                name="emailMessage"
                onChange={this.handleFieldChange('emailForm', 'emailField')}
                {...this.state.emailForm.emailField}
              />

              <div className="cf-app-segment copy-note-button">
                <div className="cf-push-left">
                  <CopyToClipboard text={this.state.emailForm.emailField.value}>
                    <Button
                      name="copyNote"
                      classNames={['usa-button-secondary usa-button-hover']}>
                      <i className="fa fa-files-o" aria-hidden="true"></i>
                   Copy note
                    </Button>
                  </CopyToClipboard>
                </div>
              </div>
            </div>

            <div className="route-claim-confirmNote-wrapper">
              <Checkbox
                label="I confirm that I have sent an email to route this claim."
                name="confirmEmail"
                onChange={this.handleFieldChange('emailForm', 'confirmBox')}
                {...this.state.emailForm.confirmBox}
                required
              />
            </div>

          </div>

          <div className="cf-app-segment" id="establish-claim-buttons">
            <div className="cf-push-left">
              <Button
                name={this.props.backToDecisionReviewText}
                onClick={this.props.handleBackToDecisionReview}
                classNames={['cf-btn-link']}
              />
            </div>
            <div className="cf-push-right">
              <Button
                name="Cancel"
                onClick={this.props.handleToggleCancelTaskModal}
                classNames={['cf-btn-link']}
              />
              <Button
                app="dispatch"
                name="Finish routing claim"
                classNames={['usa-button-primary']}
                disabled={!this.state.emailForm.confirmBox.value}
                onClick={this.props.handleEmailSubmit}
                loading={this.props.loading}
              />
            </div>
          </div>
        </div>
      }
    </div>;
  }
}

EstablishClaimEmail.propTypes = {
  appeal: PropTypes.object.isRequired,
  handleToggleCancelTaskModal: PropTypes.func.isRequired,
  handleBackToDecisionReview: PropTypes.func.isRequired,
  backToDecisionReviewText: PropTypes.string.isRequired,
  handleEmailSubmit: PropTypes.func.isRequired,
  regionalOffice: PropTypes.string,
  regionalOfficeEmail: PropTypes.arrayOf(PropTypes.string)
};

const mapStateToProps = (state) => ({
  specialIssues: state.specialIssues,
  loading: state.establishClaim.loading,
  featureToggles: state.ui.featureToggles
});

const mapDispatchToProps = (dispatch, ownProps) => ({
  handleToggleCancelTaskModal: () => {
    dispatch({ type: Constants.TOGGLE_CANCEL_TASK_MODAL });
  },
  handleEmailSubmit: () => {
    ownProps.handleAlertClear();
    dispatch({ type: Constants.TRIGGER_LOADING,
      payload: { value: true } });

    const emailRoId = getSpecialIssuesRegionalOfficeCode(
      ownProps.specialIssuesRegionalOffice,
      ownProps.appeal.regional_office_key
    );

    const data = ApiUtil.convertToSnakeCase({
      emailRoId,
      emailRecipient: ownProps.regionalOfficeEmail.join(', ')
    });

    return ApiUtil.post(`/dispatch/establish-claim/${ownProps.taskId}/email-complete`, { data }).
      then(() => {
        WindowUtil.reloadPage();
      }, () => {
        ownProps.handleAlert(
          'error',
          'Error',
          'There was an error while completing the task. Please try again later'
        );
        dispatch({ type: Constants.TRIGGER_LOADING,
          payload: { value: false } });
      });
  }
});

const ConnectedEstablishClaimEmail = connect(
  mapStateToProps,
  mapDispatchToProps
)(EstablishClaimEmail);

export default ConnectedEstablishClaimEmail;
