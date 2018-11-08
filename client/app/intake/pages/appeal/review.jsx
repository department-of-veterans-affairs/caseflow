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
  setClaimantNotVeteran,
  setClaimant,
  setPayeeCode,
  setLegacyOptInApproved
} from '../../actions/ama';
import { setReceiptDate } from '../../actions/intake';
import { PAGE_PATHS, INTAKE_STATES, FORM_TYPES } from '../../constants';
import { getIntakeStatus } from '../../selectors';
import ErrorAlert from '../../components/ErrorAlert';

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
      reviewIntakeError,
      featureToggles
    } = this.props;

    switch (appealStatus) {
    case INTAKE_STATES.NONE:
      return <Redirect to={PAGE_PATHS.BEGIN} />;
    case INTAKE_STATES.COMPLETED:
      return <Redirect to={PAGE_PATHS.COMPLETED} />;
    default:
    }

    const legacyOptInEnabled = featureToggles.legacyOptInEnabled;

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

      { legacyOptInEnabled && <LegacyOptInApproved
        value={legacyOptInApproved === null ? null : legacyOptInApproved.toString()}
        onChange={this.props.setLegacyOptInApproved}
        errorMessage={legacyOptInApprovedError}
      /> }
    </div>;
  }
}

const SelectClaimantConnected = connect(
  ({ appeal, intake }) => ({
    allPayeeCodes: true,
    claimantNotVeteran: appeal.claimantNotVeteran,
    claimant: appeal.claimant,
    payeeCode: appeal.payeeCode,
    relationships: appeal.relationships,
    benefitType: appeal.benefitType,
    formType: intake.formType
  }),
  (dispatch) => bindActionCreators({
    setClaimantNotVeteran,
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
