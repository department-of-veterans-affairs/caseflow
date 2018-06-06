import React from 'react';
import RadioField from '../../components/RadioField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';
import { setDifferentClaimantOption } from '../actions/common';
import { formatRadioOptions } from '../util';

export default class DifferentClaimant extends React.PureComponent {
  render = () => {
    const {
      differentClaimantOption,
      setDifferentClaimantOption
    } = this.props;

    let showClaimants = differentClaimantOption === 'true'

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

      {showClaimants && <ClaimantOptions />}
    </div>;
  }
};

class ClaimantOptions extends React.PureComponent {
  render = () => {

    const claimantLabel = "Please select the claimant listed on the form. " +
    "If you do not see the claimant, you will need to add it through SHARE, " +
    "then refresh this page.";

    const fakeClaimants = [
      "Joe Snuffy, Spouse",
      "Name 2, Relationship"
    ];

    const fakeClaimantOptions = formatRadioOptions(fakeClaimants);

    return <div className="cf-claimant-options">
      <RadioField
        name="claimant-options"
        label={claimantLabel}
        strongLabel
        vertical
        options={fakeClaimantOptions}
      />
    </div>;
  }
};
