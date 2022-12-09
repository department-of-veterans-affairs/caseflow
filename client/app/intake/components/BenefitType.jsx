import React from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import { formatBenefitTypeRadioOptions, formatSearchableDropdownOptions } from '../util';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class BenefitType extends React.PureComponent {
  asRadioField = () => {
    const {
      value,
      errorMessage,
      onChange,
      register,
      userCanSelectVha,
      featureToggles,
    } = this.props;

    // If the feature toggle is off then all users should be able to select vha
    const canSelectVhaBenefit = featureToggles.vhaClaimReviewEstablishment ? userCanSelectVha : true;

    return <div className="cf-benefit-type" style={{ marginTop: '10px' }} >
      <RadioField
        name="benefit-type-options"
        label="What is the Benefit Type?"
        strongLabel
        vertical
        options={formatBenefitTypeRadioOptions(BENEFIT_TYPES, canSelectVhaBenefit)}
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
  asDropdown: PropTypes.bool,
  formName: PropTypes.string.isRequired,
  benefitTypes: PropTypes.object,
  featureToggles: PropTypes.object,
  userCanSelectVha: PropTypes.bool
};
