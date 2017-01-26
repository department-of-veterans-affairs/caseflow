import React, { PropTypes } from 'react';

import Button from '../../components/Button';
import TextField from '../../components/TextField';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

export const MODIFIER_OPTIONS = [
  '170',
  '172'
];

export default class EstablishClaimForm extends React.Component {
  render() {
    let {
      claimLabelValue,
      claimForm,
      handleCreateEndProduct,
      handleCancelTask,
      handleFieldChange,
      loading,
      validModifiers
    } = this.props;


    return <div>
      <form noValidate id="end_product">
        <div className="cf-app-segment cf-app-segment--alt">
          <h1>Create End Product</h1>
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
           onChange={handleFieldChange('claimForm', 'endProductModifier')}
           readOnly={validModifiers.length === 1}
           {...claimForm.endProductModifier}
          />
          <DateSelector
           label="Decision Date"
           name="date"
           onChange={handleFieldChange('claimForm', 'date')}
           required={true}
           {...claimForm.date}
          />
          <TextField
           label="Station of Jurisdiction"
           name="stationOfJurisdiction"
           readOnly={true}
           {...claimForm.stationOfJurisdiction}
          />
          <Checkbox
           label="Gulf War Registry Permit"
           name="gulfWarRegistry"
           {...claimForm.gulfWarRegistry}
           onChange={handleFieldChange('claimForm', 'gulfWarRegistry')}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter"
           name="suppressAcknowledgementLetter"
           {...claimForm.suppressAcknowledgementLetter}
           onChange={handleFieldChange('claimForm', 'suppressAcknowledgementLetter')}
          />
        </div>
      </form>
      <div className="cf-app-segment" id="establish-claim-buttons">
        <div className="cf-push-right">
          <Button
            name="Cancel"
            onClick={handleCancelTask}
            classNames={["cf-btn-link", "cf-adjacent-buttons"]}
          />
          <Button
            name="Create End Product"
            loading={loading}
            onClick={handleCreateEndProduct}
          />
        </div>
      </div>
    </div>;
  }
}

EstablishClaimForm.propTypes = {
  claimForm: PropTypes.object.isRequired,
  claimLabelValue: PropTypes.string.isRequired,
  handleFieldChange: PropTypes.func.isRequired,
  validModifiers: PropTypes.arrayOf(PropTypes.string).isRequired
};
