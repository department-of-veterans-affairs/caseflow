import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as yup from 'yup';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import {
  BOOLEAN_RADIO_OPTIONS,
  BOOLEAN_RADIO_OPTIONS_DISABLED_FALSE,
  GENERIC_FORM_ERRORS,
  DECEASED_PAYEE_CODES,
  LIVING_PAYEE_CODES,
  VBMS_BENEFIT_TYPES
} from '../constants';
import { convertStringToBoolean } from '../util';
import {
  ADD_RELATIONSHIPS,
  CLAIMANT_NOT_FOUND_END,
  DECEASED_CLAIMANT_TITLE,
  DECEASED_CLAIMANT_MESSAGE,
  NO_RELATIONSHIPS,
  SELECT_CLAIMANT_LABEL,
  SELECT_NON_LISTED_CLAIMANT_LABEL,
} from 'app/../COPY';
import Alert from 'app/components/Alert';
import Button from 'app/components/Button';

const email = React.createElement(
  'a',
  {
    href:
      'mailto:VACaseflowIntake@va.gov?Subject=Add%20claimant%20to%20Corporate%20Database',
  },
  'email'
);

const RemovableRadioLabel = ({ text, onRemove, notes }) => (
  <>
    <span>{text}</span>{' '}
    {onRemove && (
      <Button
        linkStyling
        onClick={onRemove}
        classNames={['remove-item']}
        styling={{ style: { marginTop: '-1rem' } }}
      >
        <i className="fa fa-trash-o" aria-hidden="true" /> Remove
      </Button>
    )}
    <br />
    <span>
      <i>{notes}</i>
    </span>
  </>
);

RemovableRadioLabel.propTypes = {
  text: PropTypes.string,
  onRemove: PropTypes.func,
  notes: PropTypes.string,
};

const claimantNotListedOpt = {
  value: 'claimant_not_listed',
  displayText: 'Claimant not listed',
};

export const SelectClaimant = (props) => {
  const {
    formType,
    benefitType,
    isVeteranDeceased,
    veteranIsNotClaimant,
    veteranIsNotClaimantError,
    setVeteranIsNotClaimant,
    claimant,
    claimantError,
    setClaimant,
    relationships,
    payeeCode,
    payeeCodeError,
    setPayeeCode,
    featureToggles
  } = props;

  const [newClaimant] = useState(null);
  const isAppeal = (formType === 'appeal');
  const isNotRamp = (formType !== 'ramp_refiling', formType !== 'ramp_election');

  const showClaimantNotListedOption = useMemo(() => {
    return (
      ((isNotRamp && featureToggles.hlrScUnrecognizedClaimants) || isAppeal) &&
       !VBMS_BENEFIT_TYPES.includes(benefitType)
    );
  }, [formType, benefitType]);

  const enableAddClaimant = useMemo(
    () => showClaimantNotListedOption && veteranIsNotClaimant,
    [showClaimantNotListedOption, veteranIsNotClaimant]
  );

  const radioOpts = useMemo(() => {
    return [
      ...relationships,
      ...(newClaimant ? [newClaimant] : []),
      // Conditionally include "Claimant not listed" option
      ...(enableAddClaimant ? [claimantNotListedOpt] : []),
    ];
  }, [newClaimant, relationships, enableAddClaimant]);

  const shouldShowPayeeCode = useMemo(() => {
    return (
      !isAppeal && VBMS_BENEFIT_TYPES.includes(benefitType)
    );
  }, [formType, benefitType]);

  const handleVeteranIsNotClaimantChange = (value) => {
    const boolValue = convertStringToBoolean(value);

    setVeteranIsNotClaimant(boolValue);
    setClaimant({
      claimant: null,
      claimantType: boolValue ? 'dependent' : 'veteran',
    });
  };
  const handleSelectNonVeteran = (value) => {
    const claimantType = value === 'claimant_not_listed' ? 'other' : 'dependent';

    if (newClaimant && value === newClaimant.value) {
      setClaimant({
        claimant: value || null,
        claimantName: newClaimant.claimantName,
        claimantType: newClaimant.claimantType,
      });
    } else {
      setClaimant({ claimant: value,
        claimantType });
    }
  };
  const handlePayeeCodeChange = (event) =>
    setPayeeCode(event ? event.value : null);

  const hasRelationships = relationships.length > 0;
  const showClaimants = ['true', true].includes(veteranIsNotClaimant);

  const claimantLabel = () => {
    return (
      <p
        id={showClaimantNotListedOption ? 'nonListedClaimantLabel' : 'claimantLabel'}
        style={{ marginTop: '8.95px', marginBottom: '-25px' }}
      >
        {showClaimantNotListedOption ? SELECT_NON_LISTED_CLAIMANT_LABEL : SELECT_CLAIMANT_LABEL}

        <br />
        <br />
      </p>
    );
  };

  const noClaimantsCopy = () => {
    return (
      <p id="noClaimants" className="cf-red-text">
        {NO_RELATIONSHIPS}
        {ADD_RELATIONSHIPS}
        {email}
        {CLAIMANT_NOT_FOUND_END}
        <br />
        <br />
      </p>
    );
  };

  const claimantOptions = () => {
    return (
      <div>
        <RadioField
          name="claimant-options"
          label={claimantLabel()}
          strongLabel
          vertical
          options={radioOpts}
          onChange={handleSelectNonVeteran}
          value={claimant ?? ''}
          errorMessage={claimantError || props.errors?.['claimant-options']?.message}
          inputRef={props.register}
        />

        {shouldShowPayeeCode && (
          <SearchableDropdown
            name="cf-payee-code"
            strongLabel
            label="What is the payee code for this claimant?"
            placeholder="Select"
            options={
              isVeteranDeceased ? DECEASED_PAYEE_CODES : LIVING_PAYEE_CODES
            }
            value={payeeCode}
            errorMessage={payeeCodeError}
            onChange={(event) => handlePayeeCodeChange(event)}
          />
        )}
      </div>
    );
  };

  const alertStyling = css({
    width: '463px'
  });

  const deceasedVeteranAlert = () => {
    return (
      <Alert
        lowerMargin
        styling={alertStyling}
        type="warning"
        message={`${DECEASED_CLAIMANT_TITLE} ${DECEASED_CLAIMANT_MESSAGE}`}
      />
    );
  };

  let veteranClaimantOptions = BOOLEAN_RADIO_OPTIONS;
  const showDeceasedVeteranAlert = isVeteranDeceased && veteranIsNotClaimant === false && isAppeal;

  if (isVeteranDeceased && !isAppeal) {
    // disable veteran claimant option if veteran is deceased
    veteranClaimantOptions = BOOLEAN_RADIO_OPTIONS_DISABLED_FALSE;
    // set claimant value to someone other than the veteran
    setVeteranIsNotClaimant(true);
  }

  return (
    <div className="cf-different-claimant" style={{ marginTop: '10px' }}>
      <RadioField
        name="different-claimant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={veteranClaimantOptions}
        onChange={handleVeteranIsNotClaimantChange}
        errorMessage={veteranIsNotClaimantError || props.errors?.['different-claimant-option']?.message}
        value={
          veteranIsNotClaimant === null ?
            null :
            veteranIsNotClaimant?.toString()
        }
        inputRef={props.register}
      />

      {showDeceasedVeteranAlert && deceasedVeteranAlert()}
      {showClaimants && (
        (enableAddClaimant || hasRelationships || newClaimant) ?
          claimantOptions() :
          noClaimantsCopy()
      )}
    </div>
  );
};

SelectClaimant.propTypes = {
  benefitType: PropTypes.string,
  formType: PropTypes.string,
  isVeteranDeceased: PropTypes.bool,
  veteranIsNotClaimant: PropTypes.oneOfType([PropTypes.bool, PropTypes.string]),
  veteranIsNotClaimantError: PropTypes.string,
  setVeteranIsNotClaimant: PropTypes.func,
  claimant: PropTypes.string,
  claimantError: PropTypes.string,
  setClaimant: PropTypes.func,
  relationships: PropTypes.array,
  payeeCode: PropTypes.string,
  payeeCodeError: PropTypes.string,
  setPayeeCode: PropTypes.func,
  register: PropTypes.func,
  errors: PropTypes.array,
  featureToggles: PropTypes.shape({
    hlrScUnrecognizedClaimants: PropTypes.bool
  })
};

const selectClaimantValidations = () => ({
  'claimant-options': yup.string().notRequired().
    when('different-claimant-option', {
      is: 'true',
      then: yup.string().required(GENERIC_FORM_ERRORS.blank)
    }),
});

export { selectClaimantValidations };
export default SelectClaimant;
