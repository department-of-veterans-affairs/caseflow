import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import RadioField from '../../../components/RadioField';
import DateSelector from '../../../components/DateSelector';
import Button from '../../../components/Button';
import Alert from '../../../components/Alert';
import { Redirect } from 'react-router-dom';
import _ from 'lodash';
import { PAGE_PATHS, INTAKE_STATES, REVIEW_OPTIONS, REQUEST_STATE } from '../../constants';
import { setAppealDocket, confirmIneligibleForm } from '../../actions/rampRefiling';
import { setReceiptDate, setOptionSelected } from '../../actions/intake';
import { toggleIneligibleError } from '../../util';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

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
      reviewIntakeError
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
          Contact the Veteran to verify their lane selection. If you are unable to reach
          the Veteran, send a letter indicating that their selected lane is not available,
          and that they may clarify their lane selection within 30 days. <br />
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

      <DateSelector
        name="receipt-date"
        label="What is the Receipt Date of this form?"
        value={receiptDate}
        onChange={this.props.setReceiptDate}
        errorMessage={receiptDateError}
        strongLabel
      />

      <RadioField
        name="opt-in-election"
        label="Which review lane did the Veteran select?"
        strongLabel
        options={reviewRadioOptions}
        onChange={this.props.setOptionSelected}
        errorMessage={optionSelectedError}
        value={optionSelected}
      />

      { optionSelected === REVIEW_OPTIONS.APPEAL.key &&
        <RadioField
          name="appeal-docket"
          label="Which type of appeal did the Veteran request?"
          strongLabel
          options={docketRadioOptions}
          onChange={this.props.setAppealDocket}
          errorMessage={appealDocketError}
          value={appealDocket}
        />
      }
    </div>;
  }
}

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
