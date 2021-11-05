import React from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import { FORM_TYPES } from 'app/intake/constants';
import { formatRadioOptions, formatSearchableDropdownOptions } from '../util';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class BenefitType extends React.PureComponent {
  // eslint-disable-next-line no-unused-vars
  omitBenefitType = (keyToRemove, { [keyToRemove]: omittedValue, ...rest }) => rest;

  updatedForms = [FORM_TYPES.SUPPLEMENTAL_CLAIM.formName, FORM_TYPES.HIGHER_LEVEL_REVIEW.formName];

  benefitTypes = this.updatedForms.includes(this.props.formName) && this.props.featureToggles.veteransReadiness ?
    this.omitBenefitType('voc_rehab', BENEFIT_TYPES) :
    this.omitBenefitType('veterans_readiness', BENEFIT_TYPES);

  asRadioField = () => {
    const {
      value,
      errorMessage,
      onChange,
      register
    } = this.props;

    return <div className="cf-benefit-type" style={{ marginTop: '10px' }} >
      <RadioField
        name="benefit-type-options"
        label="What is the Benefit Type?"
        strongLabel
        vertical
        options={formatRadioOptions(this.benefitTypes)}
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
        name="issue-benefit-type"
        label="Benefit type"
        strongLabel
        placeholder="Select or enter..."
        options={formatSearchableDropdownOptions(this.benefitTypes)}
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
  asDropdown: PropTypes.bool,
  formName: PropTypes.string.isRequired,
  benefitTypes: PropTypes.object.isRequired,
  featureToggles: PropTypes.object.isRequired,
};
