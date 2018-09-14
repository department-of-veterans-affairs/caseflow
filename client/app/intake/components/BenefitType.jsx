import React from 'react';
import RadioField from '../../components/RadioField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES.json';
import { formatRadioOptions } from '../util';

export default class BenefitType extends React.PureComponent {
  render = () => {
    const {
      value,
      errorMessage,
      onChange
    } = this.props;

    return <div className="cf-benefit-type">
      <RadioField
        name="benefit-type-options"
        label="What is the Benefit Type?"
        strongLabel
        vertical
        options={formatRadioOptions(BENEFIT_TYPES)}
        onChange={onChange}
        value={value}
        errorMessage={errorMessage}
      />
    </div>;
  }
}
