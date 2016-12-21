import React from 'react';

import RadioField from '../../components/RadioField';
import TextField from '../../components/TextField';
import DropDown from '../../components/DropDown';
import SearchableDropDown from '../../components/SearchableDropDown';
import Checkbox from '../../components/Checkbox';
import DateSelector from '../../components/DateSelector';

export const POA = [
  'None',
  'VSO',
  'Private'
];
export const CLAIM_LABEL_OPTIONS = [
  '',
  '172BVAG - BVA Grant',
  '170PGAMC - AMC-Partial Grant',
  '170RMDAMC - AMC-Remand'
];
export const MODIFIER_OPTIONS = [
  '170',
  '172',
  '165',
  '40',
  '25',
  '-1',
  'abc',
  'def',
  'ghi'
];
export const SEGMENTED_LANE_OPTIONS = [
  'Core (National)',
  'Spec Ops (National)'
];

export const render = function() {
  return (
    <form noValidate>
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
        <DropDown
         label="EP & Claim Label"
         name="claimLabel"
         options={CLAIM_LABEL_OPTIONS}
         onChange={this.handleFieldChange('form', 'claimLabel')}
         required={true}
         {...this.state.form.claimLabel}
        />
        <SearchableDropDown
         label="Modifier"
         name="modifier"
         options={MODIFIER_OPTIONS}
         onChange={this.handleFieldChange('form', 'modifier')}
         {...this.state.form.modifier}
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
         name="gulfWar"
         {...this.state.form.gulfWar}
         onChange={this.handleFieldChange('form', 'gulfWar')}
        />
        <Checkbox
         label="Suppress Acknowledgement Letter"
         name="suppressAcknowledgement"
         {...this.state.form.suppressAcknowledgement}
         onChange={this.handleFieldChange('form', 'suppressAcknowledgement')}
        />
      </div>
    </form>
  );
};
