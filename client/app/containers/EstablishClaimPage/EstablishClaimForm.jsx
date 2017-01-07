import React from 'react';

import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import DropDown from '../../components/DropDown';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

export const POA = [
  'None',
  'VSO',
  'Private'
];
export const MODIFIER_OPTIONS = [
  '170',
  '172'
];
export const SEGMENTED_LANE_OPTIONS = [
  'Core (National)',
  'Spec Ops (National)'
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
         value={this.getClaimTypeFromDecision()}
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
         name="decisionDate"
         onChange={this.handleFieldChange('form', 'decisionDate')}
         required={true}
         {...this.state.form.decisionDate}
        />
        <DropDown
         label="Segmented Lane"
         name="segmentedLane"
         options={SEGMENTED_LANE_OPTIONS}
         onChange={this.handleFieldChange('form', 'segmentedLane')}
         {...this.state.form.segmentedLane}
        />
        <TextField
         label="Station"
         name="Station"
         value="499 - National Work Queue"
         readOnly={true}
        />
        <RadioField
         label="POA"
         name="POA"
         options={POA}
         onChange={this.handleFieldChange('form', 'poa')}
         {...this.state.form.poa}
        />
        {this.hasPoa() && <div><TextField
         label="POA Code"
         name="POACode"
         {...this.state.form.poaCode}
         onChange={this.handleFieldChange('form', 'poaCode')}
        />
        <Checkbox
         label="Allow POA Access to Documents"
         name="allowPoa"
         {...this.state.form.allowPoa}
         onChange={this.handleFieldChange('form', 'allowPoa')}
        /></div>}
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
