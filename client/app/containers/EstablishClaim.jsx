import React, { PropTypes } from 'react';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';

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
      claimLabel: CLAIM_LABEL_OPTIONS[0],
      modifier: MODIFIER_OPTIONS[0],
      poa: POA[0],
      poaCode: ''
    };

  }

  handleCancelTask = () => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    handleAlertClear();

    return ApiUtil.patch(`/tasks/${id}/cancel`).then(() => {
      window.location.href = '/dispatch/establish-claim';
    }, () => {
      handleAlert('error',
        'Error',
        'There was an error while cancelling the current claim. Please try again later');
    });
  }

  handlePoaChange = (event) => {
    this.setState({
      poa: event.target.value
    });
  }

  handlePoaCodeChange = (event) => {
    this.setState({
      poaCode: event.target.value
    });
  }

  handleClaimLabelChange = (event) => {
    this.setState({
      claimLabel: event.target.value
    });
  }

  hasPoa() {
    return this.state.poa === 'VSO' || this.state.poa === 'Private';
  }

  // TODO (mdbenjam): This is not being used right now, remove if
  // we decide this is not how we want the modifier to work.
  static getModifier(claim) {
    let modifier = MODIFIER_OPTIONS[0];

    MODIFIER_OPTIONS.forEach((option) => {
      if (claim.startsWith(option)) {
        modifier = option;
      }
    });

    return modifier;
  }

  render() {
    let { task } = this.props;
    let { appeal } = task;
    let { poa, poaCode, claimLabel } = this.state;

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
          />
          <DateSelector
           label="Decision Date"
           name="DecisionDate"
           readOnly={true}
           value={appeal.decision_date}
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
           selected={poa}
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
           checked={false}
          /></div>}
          <Checkbox
           label="Gulf War Registry Permit"
           name="GulfWar"
           checked={false}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter"
           name="SuppressAcknowledgement"
           checked={false}
          />
        </div>
        <div className="cf-app-segment">
          <a href="#back" className="cf-btn-link">{'\u00AB'}Back to preview</a>
          <button type="submit" className="cf-push-right cf-submit">
            Create End Product
          </button>
        </div>
        <div className="cf-app-segment">
          <button type="button" className="cf-btn-link" onClick={this.handleCancelTask}>
            Cancel
          </button>
        </div>
      </form>
    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
