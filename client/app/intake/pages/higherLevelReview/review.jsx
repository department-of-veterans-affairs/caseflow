import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { Redirect } from 'react-router-dom';
import RadioField from '../../../components/RadioField';
import DateSelector from '../../../components/DateSelector';
import CancelButton from '../../components/CancelButton';
import Button from '../../../components/Button';
import SelectClaimant from '../../components/SelectClaimant';
import { setInformalConference, setSameOffice } from '../../actions/higherLevelReview';
import { submitReview, setClaimantNotVeteran, setClaimant, setPayeeCode } from '../../actions/ama';
import { setReceiptDate } from '../../actions/common';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES, BOOLEAN_RADIO_OPTIONS } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

class Review extends React.PureComponent {
  render() {
    const {
      higherLevelReviewStatus,
      veteranName,
      receiptDate,
      receiptDateError,
      informalConference,
      informalConferenceError,
      sameOffice,
      sameOfficeError,
      reviewIntakeError
    } = this.props;

    switch (higherLevelReviewStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    return <div>
      <h1>Review { veteranName }'s Request for Higher-Level Review (VA Form 20-0988)</h1>

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
        name="informal-conference"
        label="Did the Veteran request an informal conference?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={this.props.setInformalConference}
        errorMessage={informalConferenceError}
        value={informalConference === null ? null : informalConference.toString()}
      />

      <RadioField
        name="same-office"
        label="Did the Veteran request review by the same office?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={this.props.setSameOffice}
        errorMessage={sameOfficeError}
        value={sameOffice === null ? null : sameOffice.toString()}
      />

      <SelectClaimantConnected />
    </div>;
  }
}

const SelectClaimantConnected = connect(
  ({ higherLevelReview }) => ({
    claimantNotVeteran: higherLevelReview.claimantNotVeteran,
    claimant: higherLevelReview.claimant,
    payeeCode: higherLevelReview.payeeCode,
    relationships: higherLevelReview.relationships
  }),
  (dispatch) => bindActionCreators({
    setClaimantNotVeteran,
    setClaimant,
    setPayeeCode
  }, dispatch)
)(SelectClaimant);

class ReviewNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.submitReview(this.props.intakeId, this.props.higherLevelReview, 'higherLevelReview').then(
      () => this.props.history.push('/finish')
    );
  }

  render = () =>
    <Button
      name="submit-review"
      onClick={this.handleClick}
      loading={this.props.requestState === REQUEST_STATE.IN_PROGRESS}
      legacyStyling={false}
    >
      Continue to next step
    </Button>;
}

const ReviewNextButtonConnected = connect(
  ({ higherLevelReview, intake }) => ({
    intakeId: intake.id,
    requestState: higherLevelReview.requestStatus.submitReview,
    higherLevelReview
  }),
  (dispatch) => bindActionCreators({
    submitReview
  }, dispatch)
)(ReviewNextButton);

export class ReviewButtons extends React.PureComponent {
  render = () =>
    <div>
      <CancelButton />
      <ReviewNextButtonConnected history={this.props.history} />
    </div>
}

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    higherLevelReviewStatus: getIntakeStatus(state),
    receiptDate: state.higherLevelReview.receiptDate,
    receiptDateError: state.higherLevelReview.receiptDateError,
    informalConference: state.higherLevelReview.informalConference,
    informalConferenceError: state.higherLevelReview.informalConferenceError,
    sameOffice: state.higherLevelReview.sameOffice,
    sameOfficeError: state.higherLevelReview.sameOfficeError,
    reviewIntakeError: state.higherLevelReview.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setInformalConference,
    setSameOffice,
    setReceiptDate
  }, dispatch)
)(Review);
