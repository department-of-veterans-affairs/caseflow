import React, { PropTypes } from 'react';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

import * as Constants from '../../establishClaim/constants/constants';
import { connect } from 'react-redux';

export const MODIFIER_OPTIONS = [
  '170',
  '172'
];

export class EstablishClaimForm extends React.Component {
  render() {
    let {
      loading,
      claimLabelValue,
      decisionDate,
      establishClaimForm,
      handleSubmit,
      handleCancelTask,
      handleFieldChange,
      handleBackToDecisionReview,
      validModifiers
    } = this.props;


    return <div>
      <form noValidate id="end_product">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Route Claim: Create End Product</h1>
          <TextField
           label="Benefit Type"
           name="BenefitType"
           value="C&P Live"
           readOnly={true}
          />
          <TextField
           label="Payee"
           name="Payee"
           value="00 - Veteran"
           readOnly={true}
          />
          <TextField
           label="EP & Claim Label"
           name="claimLabel"
           readOnly={true}
           value={claimLabelValue}
          />
          <DropDown
           label="Modifier"
           name="endProductModifier"
           options={validModifiers}
           onChange={handleFieldChange('endProductModifier')}
           readOnly={validModifiers.length === 1}
           value={establishClaimForm.endProductModifier}
          />
          <DateSelector
           label="Decision Date"
           name="date"
           readOnly={true}
           value={decisionDate}
          />
          <TextField
           label="Station of Jurisdiction"
           name="stationOfJurisdiction"
           readOnly={true}
           value={establishClaimForm.stationOfJurisdiction}
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
            name="< Back to Decision Review"
            onClick={handleBackToDecisionReview}
            classNames={["cf-btn-link"]}
          />
        </div>
        <div className="cf-push-right">
          <Button
            name="Cancel"
            onClick={handleCancelTask}
            classNames={["cf-btn-link", "cf-adjacent-buttons"]}
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
  handleFieldChange: PropTypes.func.isRequired,
  handleSubmit: PropTypes.func.isRequired,
  validModifiers: PropTypes.arrayOf(PropTypes.string).isRequired
};

/*
 * This function tells us which parts of the global
 * application state should be passed in as props to
 * the rendered component.
 */
const mapStateToProps = (state) => {
  return {
    establishClaimForm: state.establishClaimForm
  };
};

const mapDispatchToProps = (dispatch) => {
  return {
    handleFieldChange: (field) => (value) => {
      dispatch({
        type: Constants.CHANGE_ESTABLISH_CLAIM_FIELD,
        payload: {
          field,
          value
        }
      });
    }
  }
}

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
