import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import RadioField from '../../../components/RadioField';
import DateSelector from '../../../components/DateSelector';
import CancelButton from '../../components/CancelButton';
import { Redirect } from 'react-router-dom';
import Button from '../../../components/Button';
import _ from 'lodash';
import { submitReview } from '../../actions/rampElection';
import { setReceiptDate, setOptionSelected } from '../../actions/common';
import { REQUEST_STATE, PAGE_PATHS, INTAKE_STATES, REVIEW_OPTIONS } from '../../constants';
import { getIntakeStatus } from '../../selectors';

class Review extends React.PureComponent {
  render() {
    const {
      rampElectionStatus,
      veteranName,
      optionSelected,
      optionSelectedError,
      receiptDate,
      receiptDateError
    } = this.props;

    switch (rampElectionStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const rampElectionReviewOptions = _.reject(REVIEW_OPTIONS, REVIEW_OPTIONS.APPEAL);
    const radioOptions = _.map(rampElectionReviewOptions, (option) => ({
      value: option.key,
      displayText: option.name
    }));

    return <div>
      <h1>Review { veteranName }'s Opt-In Election Form</h1>

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
        label="Which review lane did the veteran select?"
        strongLabel
        options={radioOptions}
        onChange={this.props.setOptionSelected}
        errorMessage={optionSelectedError}
        value={optionSelected}
      />

    </div>;
  }
}

class ReviewNextButton extends React.PureComponent {
  handleClick = () => {
    this.props.submitReview(this.props.intakeId, this.props.rampElection).then(
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
  ({ rampElection, intake }) => ({
    intakeId: intake.id,
    requestState: rampElection.requestStatus.submitReview,
    rampElection
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
    rampElectionStatus: getIntakeStatus(state),
    optionSelected: state.rampElection.optionSelected,
    optionSelectedError: state.rampElection.optionSelectedError,
    receiptDate: state.rampElection.receiptDate,
    receiptDateError: state.rampElection.receiptDateError
  }),
  (dispatch) => bindActionCreators({
    setOptionSelected,
    setReceiptDate
  }, dispatch)
)(Review);
