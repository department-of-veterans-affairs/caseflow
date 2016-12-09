import React, { PropTypes } from 'react';
import ApiUtil from '../util/ApiUtil';

import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';
import Modal from '../components/Modal';
import Button from '../components/Button';

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
      allowPoa: false,
      claimLabel: CLAIM_LABEL_OPTIONS[0],
      gulfWar: false,
      loading: false,
      modifier: MODIFIER_OPTIONS[0],
      poa: POA[0],
      poaCode: '',
      segmentedLane: SEGMENTED_LANE_OPTIONS[0],
      suppressAcknowledgement: false
    };
  }

  handleSubmit = (event) => {
    this.setState({
      loading: true
    });

    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    event.preventDefault();
    handleAlertClear();

    let data = {
      claim: ApiUtil.convertToSnakeCase(this.state)
    };

    return ApiUtil.post(`/dispatch/establish-claim/${id}/perform`, { data }).then(() => {
      window.location.href = `/dispatch/establish-claim/${id}/complete`;
    }, () => {
      this.setState({
        loading: false
      });
      handleAlert(
        'error',
        'Error',
        'There was an error while submitting the current claim. Please try again later'
      );
    });
  }

  handleCancelTask = () => {
    let { id } = this.props.task;
    let { handleAlert, handleAlertClear } = this.props;

    handleAlertClear();

    return ApiUtil.patch(`/tasks/${id}/cancel`).then(() => {
      window.location.href = '/dispatch/establish-claim';
    }, () => {
      handleAlert(
        'error',
        'Error',
        'There was an error while cancelling the current claim. Please try again later'
      );
    });
  }

  handleChange = (key, value) => {
    let output = {};

    output[key] = value;
    this.setState(output);
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
    let {
      allowPoa,
      claimLabel,
      gulfWar,
      modifier,
      poa,
      poaCode,
      segmentedLane,
      suppressAcknowledgement,
      loading
    } = this.state;

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
           label="Claim Label"
           name="claimLabel"
           options={CLAIM_LABEL_OPTIONS}
           onChange={this.handleChange}
           value={claimLabel}
          />
          <DropDown
           label="Modifier"
           name="modifier"
           options={MODIFIER_OPTIONS}
           onChange={this.handleChange}
           value={modifier}
          />
          <DateSelector
           label="Decision Date"
           name="decisionDate"
           readOnly={true}
           value={appeal.decision_date}
          />
          <DropDown
           label="Segmented Lane"
           name="segmentedLane"
           options={SEGMENTED_LANE_OPTIONS}
           onChange={this.handleChange}
           value={segmentedLane}
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
           name="allowPoa"
           value={allowPoa}
           onChange={this.handleChange}
          /></div>}
          <Checkbox
           label="Gulf War Registry Permit"
           name="gulfWar"
           value={gulfWar}
           onChange={this.handleChange}
          />
          <Checkbox
           label="Suppress Acknowledgement Letter"
           name="suppressAcknowledgement"
           value={suppressAcknowledgement}
           onChange={this.handleChange}
          />
        </div>
        <div className="cf-app-segment">
          <a
           href={`/dispatch/establish-claim/${this.props.task.id}/review`}
           className="cf-btn-link">
            {'\u00AB'}Back to review
          </a>
          <Button
            name="Create End Product"
            loading={loading}
            onClick={this.handleSubmit}
          />
        </div>
        <div className="cf-app-segment">
          <button type="button" className="cf-btn-link" onClick={this.handleCancelTask}>
            Cancel
          </button>
        </div>
        <Modal
          title="My test modal"
          content="This is a test modal, soon it will have real content"
          />
      </form>

    );
  }
}

EstablishClaim.propTypes = {
  task: PropTypes.object.isRequired
};
