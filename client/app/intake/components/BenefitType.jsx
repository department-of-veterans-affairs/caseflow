import React from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import BENEFIT_TYPES from '../../../constants/BENEFIT_TYPES';
import { FORM_TYPES } from 'app/intake/constants';
import { formatRadioOptions, formatSearchableDropdownOptions } from '../util';
import SearchableDropdown from '../../components/SearchableDropdown';

export default class BenefitType extends React.PureComponent {

   nonSupplementalClaimBenefitTypes = () => {
     const benefitTypes = { ...BENEFIT_TYPES };

     delete benefitTypes.veterans_readiness;

     return benefitTypes;
   };

  supplementalClaimBenefitTypes = (props) => {
    if (!props.featureToggles.veteransReadiness) {
      return this.nonSupplementalClaimBenefitTypes();
    }

    const benefitTypes = { ...BENEFIT_TYPES };

    delete benefitTypes.voc_rehab;

    return benefitTypes;
  };
  benefitTypes = this.props.formName === FORM_TYPES.SUPPLEMENTAL_CLAIM.formName ?
    this.supplementalClaimBenefitTypes(this.props) :
    this.nonSupplementalClaimBenefitTypes();

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
};
