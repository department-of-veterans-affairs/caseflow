import React from 'react';
import Modal from '../../components/Modal';
import BaseForm from '../../containers/BaseForm';
import TextareaField from '../../components/TextareaField';
import RadioField from '../../components/RadioField';
import FormField from '../../util/FormField';
import requiredValidator from '../../util/validators/RequiredValidator';
import { submitCancel } from '../actions/intake';
import {
  clearClaimant,
  clearPoa
} from '../reducers/addClaimantSlice';
import { CANCELLATION_REASONS } from '../constants';
import ApiUtil from '../../util/ApiUtil';
import { Redirect } from 'react-router-dom';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';

class CancelIntakeModal extends BaseForm {
  constructor(props) {
    super(props);
    this.state = {
      shouldShowOtherReason: false,
      cancelReasonValue: '',
      cancelOtherValue: '',
      intakeCancellationForm: {
        cancelReason: new FormField(
          '',
          requiredValidator('Make sure you’ve selected an option below.')
        ),
        cancelOther: new FormField(
          '',
          requiredValidator('Make sure you’ve filled out the comment box below.')
        )
      },
      updateCancelSuccess: false
    };
  }

  onCancellationReasonChange = (value) => {
    this.setState({
      cancelReasonValue: value
    });

    if (value === 'other') {
      this.setState({
        shouldShowOtherReason: true
      });
    } else {
      this.setState({
        shouldShowOtherReason: false
      });
    }

    this.handleFieldChange('intakeCancellationForm',
      'cancelReason')(value);
    this.validateFormAndSetErrors(
      { cancelReason:
        this.state.intakeCancellationForm.cancelReason });
  }

  onOtherReasonChange = (value) => {
    this.setState({
      cancelOtherValue: value
    });

    this.handleFieldChange('intakeCancellationForm', 'cancelOther')(value);

    if (this.state.intakeCancellationForm.cancelOther.errorMessage) {
      this.validateFormAndSetErrors(
        { cancelOther: this.state.intakeCancellationForm.cancelOther });
    }
  }

  validateForm = () => {
    if (this.state.cancelReasonValue === 'other') {
      return this.validateFormAndSetErrors(this.state.intakeCancellationForm);
    }

    return this.validateFormAndSetErrors(
      { cancelReason: this.state.intakeCancellationForm.cancelReason });
  }

  prepareData = () => {
    let intakeCancellation =
      this.getFormValues(this.state.intakeCancellationForm);

    intakeCancellation = {
      ...intakeCancellation,
      id: this.props.intakeId
    };

    return ApiUtil.convertToSnakeCase(intakeCancellation);
  }

  handleSubmitCancel = () => {
    if (!this.validateForm()) {
      return;
    }

    let data = this.prepareData();

    this.props.submitCancel(data).then(() => {
      // Clear any unrecognized claimant info upon cancellation
      this.props.clearClaimant();
      this.props.clearPoa();
    });
  }

  submitDisabled = () => (
    !((this.state.cancelReasonValue && this.state.cancelReasonValue !== 'other') || this.state.cancelOtherValue)
  )

  render() {

    let {
      closeHandler
    } = this.props;

    const cancelReasonOptions = _.map(CANCELLATION_REASONS, (reason) => ({
      value: reason.key,
      displayText: reason.name
    }));

    if (this.state.updateCancelSuccess) {
      return <Redirect to="/intake_cancellations/" />;
    }

    return <div className="intake-cancel">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Close',
            onClick: closeHandler
          },
          {
            classNames: ['usa-button', 'confirm-cancel'],
            name: 'Cancel intake',
            disabled: this.submitDisabled(),
            onClick: this.handleSubmitCancel
          }
        ]}
        visible
        closeHandler={closeHandler}
        title="Cancel Intake?">
        <RadioField
          name="Please select the reason you are canceling this intake."
          strongLabel
          options={cancelReasonOptions}
          value={this.state.cancelReasonValue}
          onChange={this.onCancellationReasonChange}
          errorMessage={this.state.
            intakeCancellationForm.cancelReason.errorMessage} />
        {this.state.shouldShowOtherReason &&
                <TextareaField
                  name="Tell us more about your situation."
                  strongLabel
                  maxlength={150}
                  onChange={this.onOtherReasonChange}
                  errorMessage={this.state.
                    intakeCancellationForm.cancelOther.errorMessage}
                  value={this.state.cancelOtherValue}
                />
        }
      </Modal>;
    </div>;
  }
}

const mapDispatchToProps = (dispatch) => bindActionCreators({
  submitCancel,
  clearClaimant,
  clearPoa
}, dispatch);

const ConnectedCancelIntakeModal = connect(
  null,
  mapDispatchToProps
)(CancelIntakeModal);

export default ConnectedCancelIntakeModal;
