import React, { PropTypes } from 'react';

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
      form,
      handleFieldChange,
      validModifiers
    } = this.props;


    return (
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
           onChange={handleFieldChange('form', 'endProductModifier')}
           readOnly={validModifiers.length === 1}
           {...form.endProductModifier}
          />
          <DateSelector
           label="Decision Date"
           name="date"
           onChange={handleFieldChange('form', 'date')}
           required={true}
           {...form.date}
          />
          <TextField
           label="Station of Jurisdiction"
           name="stationOfJurisdiction"
           readOnly={true}
           {...form.stationOfJurisdiction}
          />
          <Checkbox
           label="Gulf War Registry Permit"
           name="gulfWarRegistry"
           {...form.gulfWarRegistry}
           onChange={handleFieldChange('form', 'gulfWarRegistry')}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter"
           name="suppressAcknowledgementLetter"
           {...form.suppressAcknowledgementLetter}
           onChange={handleFieldChange('form', 'suppressAcknowledgementLetter')}
          />
        </div>
      </form>
    );
  }
}

EstablishClaimForm.propTypes = {
  claimLabelValue: PropTypes.string.isRequired,
  form: PropTypes.object.isRequired,
  handleFieldChange: PropTypes.func.isRequired,
  validModifiers: PropTypes.arrayOf(PropTypes.string).isRequired
};
