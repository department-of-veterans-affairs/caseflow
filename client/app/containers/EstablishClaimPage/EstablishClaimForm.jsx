import RadioField from '../components/RadioField';
import TextField from '../components/TextField';
import DropDown from '../components/DropDown';
import Checkbox from '../components/Checkbox';
import DateSelector from '../components/DateSelector';
import Modal from '../components/Modal';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';

export form = function() {
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
    suppressAcknowledgement
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
         onChange={this.handleFieldChange('form', 'claimLabel')}
         {...this.state.form.claimLabel}
        />
        <DropDown
         label="Modifier"
         name="modifier"
         options={MODIFIER_OPTIONS}
         onChange={this.handleFieldChange('form', 'modifier')}
         {...this.state.form.modifier}
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
}