import React from 'react';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import { BOOLEAN_RADIO_OPTIONS, DECEASED_PAYEE_CODES, LIVING_PAYEE_CODES } from '../constants';
import COPY from '../../../COPY.json';

export default class SelectClaimant extends React.PureComponent {
  handlePayeeCodeChange(event) {
    this.props.setPayeeCode(event ? event.value : null);
  }

  shouldShowPayeeCode = () => {
    const { formType, benefitType } = this.props;

    return formType !== 'appeal' &&
      (benefitType === 'compensation' || benefitType === 'pension');
  }

  render = () => {
    const {
      isVeteranDeceased,
      veteranIsNotClaimant,
      veteranIsNotClaimantError,
      setVeteranIsNotClaimant,
      claimant,
      claimantError,
      setClaimant,
      relationships,
      payeeCode,
      payeeCodeError
    } = this.props;

    const hasRelationships = relationships.length > 0;
    let showClaimants = ['true', true].includes(veteranIsNotClaimant);

    const email = React.createElement(
      'a', { href: 'mailto:jennifer.umberhind@va.gov?Subject=Add%20claimant%20to%20Corporate%20Database' }, 'email'
    );
    const claimantLabel = React.createElement(
      'p', { id: 'claimantLabel' }, COPY.CLAIMANT_NOT_FOUND_START, email, COPY.CLAIMANT_NOT_FOUND_END
    );
    const noClaimantsCopy = React.createElement(
      'p', { id: 'noClaimants',
        className: 'cf-red-text' }, COPY.NO_RELATIONSHIPS, email, COPY.CLAIMANT_NOT_FOUND_END
    );

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
          errorMessage={claimantError}
        />

        {
          this.shouldShowPayeeCode() && <SearchableDropdown
            name="cf-payee-code"
            strongLabel
            label="What is the payee code for this claimant?"
            placeholder="Select"
            options={isVeteranDeceased ? DECEASED_PAYEE_CODES : LIVING_PAYEE_CODES}
            value={payeeCode}
            errorMessage={payeeCodeError}
            onChange={(event) => this.handlePayeeCodeChange(event)} />
        }

      </div>;
    };

    return <div className="cf-different-claimant">
      <RadioField
        name="different-claimant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={BOOLEAN_RADIO_OPTIONS}
        onChange={setVeteranIsNotClaimant}
        errorMessage={veteranIsNotClaimantError}
        value={veteranIsNotClaimant === null ? null : veteranIsNotClaimant.toString()}
      />

      { showClaimants && hasRelationships && claimantOptions() }
      { showClaimants && !hasRelationships && noClaimantsCopy }

    </div>;
  }
}
