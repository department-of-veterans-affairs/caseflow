import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import RadioField from '../../../components/RadioField';
import DateSelector from '../../../components/DateSelector';
import { Redirect } from 'react-router-dom';
import _ from 'lodash';
import { setReceiptDate, setOptionSelected } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, REVIEW_OPTIONS } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import PropTypes from 'prop-types';

class Review extends React.PureComponent {
  render() {
    const {
      rampElectionStatus,
      veteranName,
      optionSelected,
      optionSelectedError,
      receiptDate,
      receiptDateError,
      reviewIntakeError
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

      { reviewIntakeError && <ErrorAlert /> }

      <DateSelector
        name="receipt-date"
        label="What is the Receipt Date of this form?"
        value={receiptDate}
        onChange={this.props.setReceiptDate}
        errorMessage={receiptDateError}
        type="date"
        strongLabel
      />

      <RadioField
        name="opt-in-election"
        label="Which review lane did the Veteran select?"
        strongLabel
        options={radioOptions}
        onChange={this.props.setOptionSelected}
        errorMessage={optionSelectedError}
        value={optionSelected}
      />
    </div>;
  }
}

Review.propTypes = {
  veteranName: PropTypes.string,
  receiptDate: PropTypes.string,
  receiptDateError: PropTypes.string,
  optionSelected: PropTypes.string,
  optionSelectedError: PropTypes.string,
  setReceiptDate: PropTypes.func,
  setOptionSelected: PropTypes.func,
  rampElectionStatus: PropTypes.string,
  reviewIntakeError: PropTypes.string
};

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    rampElectionStatus: getIntakeStatus(state),
    optionSelected: state.rampElection.optionSelected,
    optionSelectedError: state.rampElection.optionSelectedError,
    receiptDate: state.rampElection.receiptDate,
    receiptDateError: state.rampElection.receiptDateError,
    reviewIntakeError: state.rampElection.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setOptionSelected,
    setReceiptDate
  }, dispatch)
)(Review);
