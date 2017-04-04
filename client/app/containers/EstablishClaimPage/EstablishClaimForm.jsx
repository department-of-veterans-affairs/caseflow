import React, { PropTypes } from 'react';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

import SPECIAL_ISSUES from '../../constants/SpecialIssues';
import * as Constants from '../../establishClaim/constants/constants';
import { connect } from 'react-redux';

export const MODIFIER_OPTIONS = [
  '170',
  '172'
];

export class EstablishClaimForm extends React.Component {
  formattedStationOfJurisdiction() {
    let stationKey = this.props.establishClaimForm.stationOfJurisdiction;
    let suffix;

    SPECIAL_ISSUES.forEach((issue) => {
      let issuekey = issue.stationOfJurisdiction && issue.stationOfJurisdiction.key;

      // If the assigned stationKey matches a routed special issue, use the
      // routed station's location
      if (issuekey && issuekey === stationKey) {
        suffix = issue.stationOfJurisdiction.location;
      }
    });

    // ARC is a special snowflake and doens't show the state (DC)
    if (stationKey === '397') {
      suffix = 'ARC';
    }

    // If there is no routed special issue override, use the default city/state
    if (!suffix) {
      let regionalOfficeKey = this.props.regionalOfficeKey;
      suffix = `${this.props.regionalOfficeCities[regionalOfficeKey].city}, ${
          this.props.regionalOfficeCities[regionalOfficeKey].state}`;
    }

    return `${stationKey} - ${suffix}`;
  }

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
  regionalOfficeKey: PropTypes.string.isRequired,
  regionalOfficeCities: PropTypes.object.isRequired,
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
