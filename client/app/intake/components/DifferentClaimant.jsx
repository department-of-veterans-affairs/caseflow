import React from 'react';
import RadioField from '../../components/RadioField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';

export default class DifferentClaimant extends React.PureComponent {
  render = () => {
    const {
      claimantNotVeteran,
      setClaimantNotVeteran,
      claimant,
      setClaimant,
      relationships
    } = this.props;

    let showClaimants = claimantNotVeteran === 'true';

    const claimantLabel = 'Please select the claimant listed on the form. ' +
    'If you do not see the claimant, you will need to add it through SHARE, ' +
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
        value={claimantNotVeteran}
      />

      { showClaimants && claimantOptions() }
    </div>;
  }
}
