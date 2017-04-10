import React from 'react';
import { Link } from 'react-router-dom';
import Modal from '../components/Modal';
import Button from '../components/Button';
import BaseForm from '../containers/BaseForm';
import TextareaField from '../components/TextareaField';
import RadioField from '../components/RadioField';
import FormField from '../util/FormField';
import requiredValidator from '../util/validators/RequiredValidator';
import emailValidator from '../util/validators/EmailValidator';
import TextField from '../components/TextField';
import ApiUtil from '../util/ApiUtil';



// TODO: use the footer (see ConfirmHearing.jsx) everywhere,
// then delete this comment :)
export default class CancelCertificationModal extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      shouldShowOtherReason: false,
      cancellationReasonValue: "",
      otherReasonValue: "",
      emailValue: "",
      certificationCancellationForm: {
        cancellationReason: new FormField(
          '',
          requiredValidator('Make sure you’ve selected an option below.')
        ),
        otherReason: new FormField(
          '',
          requiredValidator('Make sure you’ve filled out the comment box below.')
        ),
        email: new FormField(
          '',
          emailValidator('Make sure you’ve entered a valid email address below.')
        )
      }
    };
  }

  onCancellationReasonChange = (event) => {
    this.setState({
      cancellationReasonValue: event.target.value,
    });

    if (event.target.value === "Other") {
      this.setState({
        shouldShowOtherReason: true
      })
    }
    else {
      this.setState({
        shouldShowOtherReason: false
      });
    }

    this.handleFieldChange('certificationCancellationForm', 'cancellationReason')(event.target.value);
    this.validateFormAndSetErrors({ cancellationReason: this.state.certificationCancellationForm.cancellationReason});
  }

  onOtherReasonChange = (value) => {
    this.setState({
      otherReasonValue: value,
    });

    this.handleFieldChange('certificationCancellationForm', 'otherReason')(value);

    if (this.state.certificationCancellationForm.otherReason.errorMessage) {
      this.validateFormAndSetErrors({ otherReason: this.state.certificationCancellationForm.otherReason});
    }
  }

  onEmailChange = (value) => {
    this.setState({
      emailValue: value,
    });

    this.handleFieldChange('certificationCancellationForm', 'email')(value);

    if (this.state.certificationCancellationForm.email.errorMessage) {
      this.validateFormAndSetErrors({ email: this.state.certificationCancellationForm.email});
    }
  }

  validateForm = () => {
    if (this.state.cancellationReasonValue === "Other") {
      return this.validateFormAndSetErrors(this.state.certificationCancellationForm);
    }
    return this.validateFormAndSetErrors({ cancellationReason: this.state.certificationCancellationForm.cancellationReason, email: this.state.certificationCancellationForm.email});
  }

  prepareData = () => {
    let certificationCancellation = this.getFormValues(this.state.certificationCancellationForm);

    certificationCancellation = {
        ...certificationCancellation,
        certificationId: this.props.certificationId
      };

    return ApiUtil.convertToSnakeCase(certificationCancellation);
  }

  submitForm = () => {

    if (!this.validateForm()) {
      return;
    }

    let data = this.prepareData();

    return ApiUtil.post(`/certification_cancellations`, { data }).
      then(() => {
        this.props.closeHandler();

      }, (error) => {
        console.log(error);

      });

  }

  render() {

    let cancelModalDisplay = this.state.modal;
    let {
      title,
      closeHandler,
      certificationId
    } = this.props;

    let cancellationReasonOptions = [
      { displayText: "VBMS and VACOLS dates didn't match and couldn't be changed",
        value: "VBMS and VACOLS dates didn't match and couldn't be changed" },
      { displayText: "Missing document could not be found",
        value: "Missing document could not be found" },
      { displayText: "Pending FOIA request",
        value: "Pending FOIA request" },
      { displayText: "Other",
        value: "Other" },
    ];

    return <div>
      <Modal
            buttons={[
              { classNames: ["cf-modal-link", "cf-btn-link"],
                name: '\u226A Go back',
                onClick: closeHandler
              },
              { classNames: ["usa-button", "usa-button-secondary"],
                name: 'Cancel certification',
                onClick: this.submitForm
              }
            ]}
            visible={true}
            closeHandler={closeHandler}
            title={title}>
            <p>
              Please explain why this case cannot be certified with Caseflow. Once you click <strong>Cancel certification</strong>, changes made to this case in Caseflow will not be saved.
            </p>
            <RadioField
              name="Why can't be this case certified in Caseflow"
              options={cancellationReasonOptions}
              value={this.state.cancellationReasonValue}
              required={true}
              onChange={this.onCancellationReasonChange}
              errorMessage={this.state.certificationCancellationForm.cancellationReason.errorMessage}/>
            {this.state.shouldShowOtherReason &&
              <TextareaField
                name="Tell us more about your situation."
                required={true}
                onChange={this.onOtherReasonChange}
                errorMessage={this.state.certificationCancellationForm.otherReason.errorMessage}
                value={this.state.otherReasonValue}
              />
            }
            <TextField
            name="What's your VA email address?"
            onChange={this.onEmailChange}
            errorMessage={this.state.certificationCancellationForm.email.errorMessage}
            value={this.state.emailValue}
            required={true}/>
      </Modal>
    </div>;
  }
}
