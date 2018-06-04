import React from 'react';
import RadioField from '../../components/RadioField';
import { BOOLEAN_RADIO_OPTIONS } from '../constants';

export default class DifferentAppelant extends React.PureComponent {
  render = () => {
    const {
      differentAppellantOption,
      setDifferentAppellantOption
    } = this.props;

    <div className="cf-different-appellant">
      <RadioField
        name="different-appellant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={setDifferentAppellantOption}
        value={differentAppellantOption}
      />
    </div>
  }
}
