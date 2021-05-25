import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import * as yup from 'yup';
import RadioField from '../../../components/RadioField';
import Button from '../../../components/Button';
import Alert from '../../../components/Alert';
import { Redirect } from 'react-router-dom';
import _ from 'lodash';
import { PAGE_PATHS, INTAKE_STATES, REVIEW_OPTIONS, REQUEST_STATE, CLAIMANT_ERRORS } from '../../constants';
import { setAppealDocket, confirmIneligibleForm } from '../../actions/rampRefiling';
import { setReceiptDate, setOptionSelected } from '../../actions/intake';
import { toggleIneligibleError } from '../../util';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import COPY from '../../../../COPY';
import PropTypes from 'prop-types';
import ReceiptDateInput, { receiptDateInputValidation } from '../receiptDateInput';

const reviewRampRefilingSchema = yup.object().shape({
  'opt-in-election': yup.string().required(CLAIMANT_ERRORS.blank),
  'appeal-docket': yup.string().notRequired().
    when('opt-in-election', {
      is: REVIEW_OPTIONS.APPEAL.key,
      then: yup.string().required(CLAIMANT_ERRORS.blank)
    }),
  ...receiptDateInputValidation()
});

class Review extends React.PureComponent {
  beginNextIntake = () => {
    this.props.confirmIneligibleForm(this.props.intakeId);
  }
  render() {
    const {
      rampRefilingStatus,
      veteranName,
      optionSelected,
      optionSelectedError,
      hasInvalidOption,
      receiptDate,
      receiptDateError,
      appealDocket,
      appealDocketError,
      submitInvalidOptionError,
      reviewIntakeError,
      errors
    } = this.props;

    switch (rampRefilingStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const reviewRadioOptions = _.map(REVIEW_OPTIONS, (option) => ({
      value: option.key,
      displayText: option.name
    }));

    const docketRadioOptions = [
      {
        value: 'direct_review',
        displayText: 'Direct Review'
      },
      {
        value: 'evidence_submission',
        displayText: 'Evidence Submission'
      },
      {
        value: 'hearing',
        displayText: 'Hearing'
      }
    ];

    return <div>
      { submitInvalidOptionError && <ErrorAlert />}

      { toggleIneligibleError(hasInvalidOption, optionSelected) &&
        <Alert title="Ineligible for Higher-Level Review" type="error" >
          {COPY.INELIGIBLE_HIGHER_LEVEL_REVIEW_ALERT} <br />
          <Button
            name="begin-next-intake"
            onClick={this.beginNextIntake}
            loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}>
            Begin next intake
          </Button>
        </Alert>
      }

      <h1>Review { veteranName }'s 21-4138 RAMP Selection Form</h1>

      { reviewIntakeError && <ErrorAlert /> }

      <ReceiptDateInput
        receiptDate={receiptDate}
        setReceiptDate={this.props.setReceiptDate}
        receiptDateError={receiptDateError}
        errors={errors}
        register={this.props.register}
      />

      <RadioField
        name="opt-in-election"
        label="Which review lane did the Veteran select?"
        strongLabel
        options={reviewRadioOptions}
        onChange={this.props.setOptionSelected}
        errorMessage={optionSelectedError || errors?.['opt-in-election']?.message}
        value={optionSelected}
        inputRef={this.props.register}
      />

      { optionSelected === REVIEW_OPTIONS.APPEAL.key &&
        <RadioField
          name="appeal-docket"
          label="Which type of appeal did the Veteran request?"
          strongLabel
          options={docketRadioOptions}
          onChange={this.props.setAppealDocket}
          errorMessage={appealDocketError || errors?.['appeal-docket']?.message}
          value={appealDocket}
          inputRef={this.props.register}
        />
      }
    </div>;
  }
}
Review.propTypes = {
  rampRefilingStatus: PropTypes.string,
  veteranName: PropTypes.string,
  optionSelected: PropTypes.string,
  optionSelectedError: PropTypes.string,
  hasInvalidOption: PropTypes.bool,
  receiptDate: PropTypes.string,
  receiptDateError: PropTypes.string,
  appealDocket: PropTypes.string,
  appealDocketError: PropTypes.string,
  submitInvalidOptionError: PropTypes.string,
  reviewIntakeError: PropTypes.string,
  setAppealDocket: PropTypes.func,
  setOptionSelected: PropTypes.func,
  setReceiptDate: PropTypes.func,
  requestState: PropTypes.string,
  intakeId: PropTypes.string,
  confirmIneligibleForm: PropTypes.func,
  register: PropTypes.func,
  errors: PropTypes.array
};

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    rampRefilingStatus: getIntakeStatus(state),
    optionSelected: state.rampRefiling.optionSelected,
    optionSelectedError: state.rampRefiling.optionSelectedError,
    hasInvalidOption: state.rampRefiling.hasInvalidOption,
    receiptDate: state.rampRefiling.receiptDate,
    receiptDateError: state.rampRefiling.receiptDateError,
    requestStatus: state.rampRefiling.requestStatus,
    intakeId: state.intake.id,
    appealDocket: state.rampRefiling.appealDocket,
    appealDocketError: state.rampRefiling.appealDocketError,
    submitInvalidOptionError: state.rampRefiling.submitInvalidOptionError,
    reviewIntakeError: state.rampRefiling.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setOptionSelected,
    setReceiptDate,
    setAppealDocket,
    confirmIneligibleForm
  }, dispatch)
)(Review);

export { reviewRampRefilingSchema };
