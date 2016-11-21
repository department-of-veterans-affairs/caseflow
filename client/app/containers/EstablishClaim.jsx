import React, { PropTypes } from 'react';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import TextareaField from '../components/TextareaField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';

const CONTESTED_CLAIMS = {
  Yes: true,
  No: false
};
const POA = [
  'None',
  'VSO',
  'Private'
];
const CLAIM_LABEL_OPTIONS = [
  ' ', 
  '172BVAG - BVA Grant', 
  '170PGAMC - AMC-Partial Grant', 
  '170RMDAMC - AMC-Remand'
];
const MODIFIER_OPTIONS = [
  '170', 
  '172'
];
const SEGMENTED_LANE_OPTIONS = [
  'Core (National)',
  'Spec Ops (National)'
];

export default class EstablishClaim extends React.Component {
  constructor(props) {
    super(props);

     // Set initial state on page render
     this.state = {
       poa: POA[0],
       poaCode: '',
       claimLabel: CLAIM_LABEL_OPTIONS[0],
       modifier: MODIFIER_OPTIONS[0]
     }

     this.handlePoaChange = this.handlePoaChange.bind(this);
     this.handlePoaCodeChange = this.handlePoaCodeChange.bind(this);
     this.handleClaimLabelChange = this.handleClaimLabelChange.bind(this);
   }

  handlePoaChange(e) {
    this.setState({
      poa: e.target.value
    });
  }

  handlePoaCodeChange(e) {
    this.setState({
      poaCode: e.target.value
    });
  }

  handleClaimLabelChange(e) {
    this.setState({
      claimLabel: e.target.value,
      modifier: this.getModifier(e.target.value)
    });
  }

  hasPoa() {
    return this.state.poa == 'VSO' || this.state.poa == 'Private';
  }

  getModifier(claim) {
    var modifier = MODIFIER_OPTIONS[0];
    MODIFIER_OPTIONS.forEach(option => {
      if (claim.startsWith(option)) {
        modifier = option;
      }
    });
    return modifier;
  }

  render() {
    let { task } = this.props;
    let { user, appeal } = task;
    let { poa, poaCode, claimLabel, modifier } = this.state;

    return (
      <form className="cf-form" noValidate>
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
           label="Claim Label"
           name="ClaimLabel"
           options={CLAIM_LABEL_OPTIONS}
           onChange={this.handleClaimLabelChange}
           selected={claimLabel}
          />
          <TextField
           label="Claim Type"
           name="ClaimType"
           value="Claim"
           invisible={true}
           readOnly={true}
          />
          <DropDown
           label="Modifier"
           name="Modifier"
           options={MODIFIER_OPTIONS}
           selected={modifier}
           readOnly={true}
          />
          <DropDown
           label="Segmented Lane"
           name="SegmentedLane"
           options={SEGMENTED_LANE_OPTIONS}
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
           checked={poa}
           options={POA}
           onChange={this.handlePoaChange}
          />
          {this.hasPoa() && <div><TextField
           label="POA Code"
           name="POACode"
           value={poaCode}
           onChange={this.handlePoaCodeChange}
          />
          <Checkbox
           label="Allow POA Access to Documents" 
           name="AllowPOA"
           isChecked={false}
          /></div>}
          <Checkbox
           label="Gulf War Registry Permit" 
           name="GulfWar"
           isChecked={false}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter" 
           name="SuppressAcknowledgement"
           isChecked={false}
          />
        </div>
        <div className="cf-app-segment">
          <a href="#back" className="cf-btn-link">{'\u00AB'}Back to preview</a>
          <button type="submit" className="cf-push-right cf-submit">Create End Product</button>
        </div>
        <div className="cf-app-segment">
          <a href="#cancel" className="cf-btn-link">Cancel</a>
        </div>
      </form>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
