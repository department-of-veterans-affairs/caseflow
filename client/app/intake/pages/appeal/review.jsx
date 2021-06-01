import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import RadioField from '../../../components/RadioField';
import DateSelector from '../../../components/DateSelector';
import { Redirect } from 'react-router-dom';
import SelectClaimant from '../../components/SelectClaimant';
import LegacyOptInApproved from '../../components/LegacyOptInApproved';
import { setDocketType } from '../../actions/appeal';
import {
  setVeteranIsNotClaimant,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/decisionReview';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';
import PropTypes from 'prop-types';

class Review extends React.PureComponent {
  render() {
    const {
      appealStatus,
      veteranName,
      receiptDate,
      receiptDateError,
      docketType,
      docketTypeError,
      legacyOptInApproved,
      legacyOptInApprovedError,
      reviewIntakeError
    } = this.props;

    switch (appealStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const docketTypeRadioOptions = [
      { value: 'direct_review',
        displayText: 'Direct Review' },
      { value: 'evidence_submission',
        displayText: 'Evidence Submission' },
      { value: 'hearing',
        displayText: 'Hearing' }
    ];

    return <div>
      <h1>Review { veteranName }'s { FORM_TYPES.APPEAL.name }</h1>

      { reviewIntakeError && <ErrorAlert {...reviewIntakeError} /> }

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
        name="docket-type"
        label="Which review option did the Veteran request?"
        strongLabel
        vertical
        options={docketTypeRadioOptions}
        onChange={this.props.setDocketType}
        errorMessage={docketTypeError}
        value={docketType}
      />

      <SelectClaimantConnected />

      <LegacyOptInApproved
        value={legacyOptInApproved}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={legacyOptInApprovedError}
      />
    </div>;
  }
}

Review.propTypes = {
  veteranName: PropTypes.string,
  receiptDate: PropTypes.string,
  receiptDateError: PropTypes.string,
  docketType: PropTypes.string,
  docketTypeError: PropTypes.string,
  legacyOptInApproved: PropTypes.bool,
  legacyOptInApprovedError: PropTypes.string,
  reviewIntakeError: PropTypes.object,
  setDocketType: PropTypes.func,
  setReceiptDate: PropTypes.func,
  setLegacyOptInApproved: PropTypes.func,
  appealStatus: PropTypes.string
};

const SelectClaimantConnected = connect(
  ({ appeal, intake, featureToggles }) => ({
    isVeteranDeceased: intake.veteran.isDeceased,
    veteranIsNotClaimant: appeal.veteranIsNotClaimant,
    veteranIsNotClaimantError: appeal.veteranIsNotClaimantError,
    claimant: appeal.claimant,
    claimantError: appeal.claimantError,
    payeeCode: appeal.payeeCode,
    relationships: appeal.relationships,
    benefitType: appeal.benefitType,
    formType: intake.formType,
    featureToggles
  }),
  (dispatch) => bindActionCreators({
    setVeteranIsNotClaimant,
    setClaimant,
    setPayeeCode
  }, dispatch)
)(SelectClaimant);

export default connect(
  (state) => ({
    veteranName: state.intake.veteran.name,
    appealStatus: getIntakeStatus(state),
    receiptDate: state.appeal.receiptDate,
    receiptDateError: state.appeal.receiptDateError,
    docketType: state.appeal.docketType,
    docketTypeError: state.appeal.docketTypeError,
    legacyOptInApproved: state.appeal.legacyOptInApproved,
    legacyOptInApprovedError: state.appeal.legacyOptInApprovedError,
    reviewIntakeError: state.appeal.requestStatus.reviewIntakeError
  }),
  (dispatch) => bindActionCreators({
    setDocketType,
    setReceiptDate,
    setLegacyOptInApproved
  }, dispatch)
)(Review);
