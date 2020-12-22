import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import {
  BOOLEAN_RADIO_OPTIONS,
  BOOLEAN_RADIO_OPTIONS_DISABLED_FALSE,
  DECEASED_PAYEE_CODES,
  LIVING_PAYEE_CODES,
} from '../constants';
import { convertStringToBoolean } from '../util';
import {
  ADD_CLAIMANT_TEXT,
  ADD_RELATIONSHIPS,
  CLAIMANT_NOT_FOUND_START,
  CLAIMANT_NOT_FOUND_END,
  NO_RELATIONSHIPS,
  SELECT_CLAIMANT_LABEL,
} from 'app/../COPY';
import Button from 'app/components/Button';
import classes from './SelectClaimant.module.scss';
import { AddClaimantModal } from './AddClaimantModal';

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
    featureToggles = {},
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
  } = props;

  const {
    attorneyFees,
    establishFiduciaryEps,
    nonVeteranClaimants,
  } = featureToggles;
  const [showClaimantModal, setShowClaimantModal] = useState(false);
  const [newClaimant, setNewClaimant] = useState(null);
  const openAddClaimantModal = () => setShowClaimantModal(true);
  const radioOpts = useMemo(() => {
    return [
      ...relationships,
      ...(newClaimant ? [newClaimant] : []),
      ...(nonVeteranClaimants ? [claimantNotListedOpt] : []),
    ];
  }, [newClaimant, relationships]);
  const allowAddClaimant = useMemo(
    () => formType === 'appeal' && attorneyFees && veteranIsNotClaimant,
    [formType, veteranIsNotClaimant, attorneyFees]
  );

  const allowFiduciary = useMemo(
    () => establishFiduciaryEps && benefitType === 'fiduciary',
    [benefitType, establishFiduciaryEps]
  );

  const handleVeteranIsNotClaimantChange = (value) => {
    const boolValue = convertStringToBoolean(value);

    setVeteranIsNotClaimant(boolValue);
    setClaimant({
      claimant: null,
      claimantType: boolValue ? 'dependent' : 'veteran',
    });
  };
  const handleRemove = () => {
    setNewClaimant(null);
    setClaimant({
      claimant: null,
      claimantType: 'dependent',
      claimantNotes: null,
    });
  };
  const handleSelectNonVeteran = (value) => {
    if (newClaimant && value === newClaimant.value) {
      setClaimant({
        claimant: value || null,
        claimantName: newClaimant.claimantName,
        claimantNotes: newClaimant.claimantNotes,
        claimantType: newClaimant.claimantType,
      });
    } else {
      setClaimant({ claimant: value, claimantType: 'dependent' });
    }
  };
  const handleAddClaimant = ({
    name,
    participantId,
    claimantType,
    claimantNotes,
  }) => {
    setNewClaimant({
      displayElem: (
        <RemovableRadioLabel
          text={`${name || 'Claimant not listed'}, Attorney`}
          onRemove={handleRemove}
          notes={claimantNotes}
        />
      ),
      value: participantId ?? '',
      defaultPayeeCode: '',
      claimantName: name,
      claimantNotes,
      claimantType,
    });
    setClaimant({
      claimant: participantId ?? null,
      claimantType,
      claimantNotes,
      claimantName: name,
    });
    setShowClaimantModal(false);
  };
  const handlePayeeCodeChange = (event) =>
    setPayeeCode(event ? event.value : null);
  const shouldShowPayeeCode = () => {
    return (
      formType !== 'appeal' &&
      (benefitType === 'compensation' ||
        benefitType === 'pension' ||
        allowFiduciary)
    );
  };

  const hasRelationships = relationships.length > 0;
  const showClaimants = ['true', true].includes(veteranIsNotClaimant);

  const claimantLabel = () => {
    let claimantNotes = props.claimantNotes;

    return (
      <p
        id="claimantLabel"
        style={{ marginTop: '8.95px', marginBottom: '0px' }}
      >
        {nonVeteranClaimants ?
          SELECT_CLAIMANT_LABEL :
          [CLAIMANT_NOT_FOUND_START, email, CLAIMANT_NOT_FOUND_END]}

        <br />
        <br />
        {attorneyFees && formType === 'appeal' && !(claimant || claimantNotes) ?
          ADD_CLAIMANT_TEXT :
          ''}
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
        {attorneyFees && formType === 'appeal' ? ADD_CLAIMANT_TEXT : ''}
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
          errorMessage={claimantError}
        />

        {shouldShowPayeeCode() && (
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

  let veteranClaimantOptions = BOOLEAN_RADIO_OPTIONS;

  if (isVeteranDeceased) {
    // disable veteran claimant option if veteran is deceased
    veteranClaimantOptions = BOOLEAN_RADIO_OPTIONS_DISABLED_FALSE;
    // set claimant value to someone other than the veteran
    setVeteranIsNotClaimant(true);
  }

  return (
    <div className="cf-different-claimant" style={{ marginTop: '18.95px' }}>
      <RadioField
        name="different-claimant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={veteranClaimantOptions}
        onChange={handleVeteranIsNotClaimantChange}
        errorMessage={veteranIsNotClaimantError}
        value={
          veteranIsNotClaimant === null ?
            null :
            veteranIsNotClaimant?.toString()
        }
      />

      {showClaimants && (hasRelationships || newClaimant) && claimantOptions()}
      {showClaimants && !hasRelationships && !newClaimant && noClaimantsCopy()}

      {allowAddClaimant && !newClaimant && (
        <>
          <Button
            classNames={['usa-button-secondary', classes.button]}
            name="+ Add Claimant"
            id="button-addClaimant"
            onClick={openAddClaimantModal}
          />

          {showClaimantModal && (
            <AddClaimantModal
              onCancel={() => setShowClaimantModal(false)}
              onSubmit={handleAddClaimant}
            />
          )}
        </>
      )}
    </div>
  );
};

SelectClaimant.propTypes = {
  benefitType: PropTypes.string,
  featureToggles: PropTypes.shape({
    attorneyFees: PropTypes.bool,
    establishFiduciaryEps: PropTypes.bool,
    nonVeteranClaimants: PropTypes.bool,
  }),
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
  claimantNotes: PropTypes.string,
};

export default SelectClaimant;
