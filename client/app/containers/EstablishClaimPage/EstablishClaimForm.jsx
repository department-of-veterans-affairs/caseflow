import React from 'react';
import PropTypes from 'prop-types';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

import { formattedStationOfJurisdiction } from '../../establishClaim/util';
import * as Constants from '../../establishClaim/constants';

import { connect } from 'react-redux';

export class EstablishClaimForm extends React.Component {
  formattedStationOfJurisdiction() {
    return formattedStationOfJurisdiction(
      this.props.stationOfJurisdiction,
      this.props.regionalOfficeKey,
      this.props.regionalOfficeCities
    );
  }

  render() {
    let {
      loading,
      claimLabelValue,
      decisionDate,
      establishClaimForm,
      handleSubmit,
      handleToggleCancelTaskModal,
      handleFieldChange,
      handleBackToDecisionReview,
      backToDecisionReviewText
    } = this.props;

    return <div>
      <form noValidate id="end_product">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Route Claim</h1>
          <h2>Create End Product</h2>
          <TextField
            label="Benefit Type"
            name="BenefitType"
            value="C&P Live"
            readOnly
          />
          <TextField
            label="Payee"
            name="Payee"
            value="00 - Veteran"
            readOnly
          />
          <TextField
            label="EP & Claim Label"
            name="claimLabel"
            readOnly
            value={claimLabelValue}
          />
          <TextField
            label="Modifier"
            name="endProductModifier"
            readOnly
            value={establishClaimForm.endProductModifier}
          />
          <DateSelector
            label="Decision Date"
            name="date"
            type="date"
            readOnly
            value={decisionDate}
          />
          <TextField
            label="Station of Jurisdiction"
            name="stationOfJurisdiction"
            readOnly
            value={this.formattedStationOfJurisdiction()}
          />
          <Checkbox
            label="Gulf War Registry Permit"
            name="gulfWarRegistry"
            value={establishClaimForm.gulfWarRegistry}
            onChange={handleFieldChange('gulfWarRegistry')}
          />
          <Checkbox
            label="Suppress Acknowledgement Letter"
            name="suppressAcknowledgementLetter"
            value={establishClaimForm.suppressAcknowledgementLetter}
            onChange={handleFieldChange('suppressAcknowledgementLetter')}
          />
        </div>
      </form>
      <div className="cf-app-segment" id="establish-claim-buttons">
        <div className="cf-push-left">
          <Button
            name={backToDecisionReviewText}
            onClick={handleBackToDecisionReview}
            classNames={['cf-btn-link']}
          />
        </div>
        <div className="cf-push-right">
          <Button
            name="Cancel"
            onClick={handleToggleCancelTaskModal}
            classNames={['cf-btn-link']}
          />
          <Button
            app="dispatch"
            name="Create End Product"
            loading={loading}
            onClick={handleSubmit}
          />
        </div>
      </div>
    </div>;
  }
}

EstablishClaimForm.propTypes = {
  establishClaimForm: PropTypes.object.isRequired,
  claimLabelValue: PropTypes.string.isRequired,
  decisionDate: PropTypes.string.isRequired,
  handleBackToDecisionReview: PropTypes.func.isRequired,
  handleToggleCancelTaskModal: PropTypes.func.isRequired,
  backToDecisionReviewText: PropTypes.string.isRequired,
  handleFieldChange: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  stationKey: PropTypes.string.isRequired,
  regionalOfficeKey: PropTypes.string.isRequired,
  regionalOfficeCities: PropTypes.object.isRequired,
  stationOfJurisdiction: PropTypes.object.isRequired,
  loading: PropTypes.bool.isRequired
};

/*
 * This function tells us which parts of the global
 * application state should be passed in as props to
 * the rendered component.
 */
const mapStateToProps = (state) => ({
  establishClaimForm: state.establishClaimForm
});

const mapDispatchToProps = (dispatch) => ({
  handleToggleCancelTaskModal: () => {
    dispatch({ type: Constants.TOGGLE_CANCEL_TASK_MODAL });
  },
  handleFieldChange: (field) => (value) => {
    dispatch({
      type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
      payload: {
        field,
        value
      }
    });
  }
});

/*
 * Creates a component that's connected to the Redux store
 * using the state & dispatch map functions and the
 * ConfirmHearing function.
 */
const ConnectedEstablishClaimForm = connect(
  mapStateToProps,
  mapDispatchToProps
)(EstablishClaimForm);

export default ConnectedEstablishClaimForm;
