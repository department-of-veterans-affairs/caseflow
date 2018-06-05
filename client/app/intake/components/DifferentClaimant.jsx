import React from 'react';
import RadioField from '../../components/RadioField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';

export default class DifferentClaimant extends React.PureComponent {
  render = () => {
    const {
      differentClaimantOption,
      setDifferentClaimantOption
    } = this.props;

    return <div className="cf-different-claimant">
      <RadioField
        name="different-claimant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={setDifferentClaimantOption}
        value={differentClaimantOption}
      />
    </div>;
  }
};
