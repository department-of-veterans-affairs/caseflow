import React from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import { formatRadioOptions, formatSearchableDropdownOptions } from '../util';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class BenefitType extends React.PureComponent {
  asRadioField = () => {
    const {
      value,
      errorMessage,
      onChange,
      register
    } = this.props;

    return <div className="cf-benefit-type">
      <RadioField
        name="benefitTypeOptions"
        label="What is the Benefit Type?"
        strongLabel
        vertical
        options={formatRadioOptions(BENEFIT_TYPES)}
        onChange={onChange}
        value={value}
        errorMessage={errorMessage}
        inputRef={register}
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
        name="benefitTypeOptions"
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

BenefitType.propTypes = {
  value: PropTypes.string,
  errorMessage: PropTypes.string,
  onChange: PropTypes.func,
  register: PropTypes.func,
  asDropdown: PropTypes.bool
};
