import React from 'react';
import RadioField from '../../components/RadioField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES.json';
import { formatRadioOptions, formatSearchableDropdownOptions } from '../util';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class BenefitType extends React.PureComponent {
  asRadioField = () => {
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
        inputRef={this.props.register}
      />
    </div>;
  }

  asDropdownField = () => {
    const {
      value,
      errorMessage,
      onChange
    } = this.props;

    return <div className="cf-benefit-type">
      <SearchableDropdown
        name="issue-benefit-type"
        label="Benefit type"
        strongLabel
        placeholder="Select or enter..."
        options={formatSearchableDropdownOptions(BENEFIT_TYPES)}
        value={value}
        onChange={onChange}
        errorMessage={errorMessage}
      />
    </div>;
  }

  render = () => {
    if (this.props.asDropdown) {
      return this.asDropdownField();
    }

    return this.asRadioField();
  }
}
