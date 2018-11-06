import React from 'react';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import { BOOLEAN_RADIO_OPTIONS, PAYEE_CODES } from '../constants';

export default class SelectClaimant extends React.PureComponent {
  handlePayeeCodeChange(event) {
    this.props.setPayeeCode(event ? event.value : null);
  }

  shouldShowPayeeCode = () => {
    const { formType, benefitType } = this.props;

    return formType !== 'appeal' &&
      (benefitType === 'compensation' || benefitType === 'pension');
  }

  render = () => {
    const {
      claimantNotVeteran,
      setClaimantNotVeteran,
      claimant,
      setClaimant,
      relationships,
      payeeCode
    } = this.props;

    let showClaimants = ['true', true].includes(claimantNotVeteran);

    const claimantLabel = 'Please select the claimant listed on the form. ' +
    'If you do not see the claimant in the options below, add them in VBMS, ' +
    'then refresh this page.';

    const claimantOptions = () => {
      return <div className="cf-claimant-options">
        <RadioField
          name="claimant-options"
          label={claimantLabel}
          strongLabel
          vertical
          options={relationships}
          onChange={setClaimant}
          value={claimant}
        />

        {
          this.shouldShowPayeeCode() && <SearchableDropdown
            name="cf-payee-code"
            strongLabel
            label="What is the payee code for this claimant?"
            placeholder="Select"
            options={PAYEE_CODES}
            value={payeeCode}
            onChange={(event) => this.handlePayeeCodeChange(event)} />
        }

      </div>;
    };

    return <div className="cf-different-claimant">
      <RadioField
        name="different-claimant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={setClaimantNotVeteran}
        value={claimantNotVeteran === null ? null : claimantNotVeteran.toString()}
      />

      { showClaimants && claimantOptions() }
    </div>;
  }
}
