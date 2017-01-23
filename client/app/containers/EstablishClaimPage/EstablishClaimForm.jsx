import React from 'react';

import TextField from '../../components/TextField';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

export const MODIFIER_OPTIONS = [
  '170',
  '172'
];

export const render = function() {
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
         value={this.getClaimTypeFromDecision().join(' - ')}
        />
        <DropDown
         label="Modifier"
         name="endProductModifier"
         options={MODIFIER_OPTIONS}
         onChange={this.handleFieldChange('form', 'endProductModifier')}
         {...this.state.form.endProductModifier}
        />
        <DateSelector
         label="Decision Date"
         name="date"
         onChange={this.handleFieldChange('form', 'date')}
         required={true}
         {...this.state.form.date}
        />
        <TextField
         label="Station"
         name="Station"
         value="499 - National Work Queue"
         readOnly={true}
        />
        <Checkbox
         label="Gulf War Registry Permit"
         name="gulfWarRegistry"
         {...this.state.form.gulfWarRegistry}
         onChange={this.handleFieldChange('form', 'gulfWarRegistry')}
        />
        <Checkbox
         label="Suppress Acknowledgement Letter"
         name="suppressAcknowledgementLetter"
         {...this.state.form.suppressAcknowledgementLetter}
         onChange={this.handleFieldChange('form', 'suppressAcknowledgementLetter')}
        />
      </div>
    </form>
  );
};
