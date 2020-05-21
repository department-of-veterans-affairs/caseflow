import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import RadioField from '../../components/RadioField';
import SearchableDropdown from '../../components/SearchableDropdown';
import {
  BOOLEAN_RADIO_OPTIONS,
  BOOLEAN_RADIO_OPTIONS_DISABLED_FALSE,
  DECEASED_PAYEE_CODES,
  LIVING_PAYEE_CODES
} from '../constants';
import COPY from '../../../COPY';
import { useSelector } from 'react-redux';
import Button from '../../components/Button';
import classes from './SelectClaimant.module.scss';
import { AddClaimantModal } from './AddClaimantModal';

const email = React.createElement(
  'a',
  { href: 'mailto:VACaseflowIntake@va.gov?Subject=Add%20claimant%20to%20Corporate%20Database' },
  'email'
);
const claimantLabel = React.createElement(
  'p',
  { id: 'claimantLabel' },
  COPY.CLAIMANT_NOT_FOUND_START,
  email,
  COPY.CLAIMANT_NOT_FOUND_END
);
const noClaimantsCopy = React.createElement(
  'p',
  { id: 'noClaimants', className: 'cf-red-text' },
  COPY.NO_RELATIONSHIPS,
  email,
  COPY.CLAIMANT_NOT_FOUND_END
);

const RemovableRadioLabel = ({ text, onRemove }) => (
  <>
    <span>{text}</span>{' '}
    {onRemove && (
      <Button linkStyling onClick={onRemove} styling={{ style: { marginTop: '-1rem' } }}>
        <i className="fa fa-trash-o" aria-hidden="true" /> Remove
      </Button>
    )}
  </>
);

RemovableRadioLabel.propTypes = {
  text: PropTypes.string,
  onRemove: PropTypes.func
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
    setPayeeCode
  } = props;

  const { attorneyFees } = useSelector((state) => state.featureToggles);
  const [showClaimantModal, setShowClaimantModal] = useState(false);
  const [newClaimant, setNewClaimant] = useState(null);
  const openAddClaimantModal = () => setShowClaimantModal(true);
  const radioOpts = useMemo(() => {
    return [...relationships, ...(newClaimant ? [newClaimant] : [])];
  }, [newClaimant, relationships]);
  const allowAddClaimant = useMemo(() => formType === 'appeal' && attorneyFees && veteranIsNotClaimant, [
    formType,
    veteranIsNotClaimant,
    attorneyFees
  ]);
  const handleRemove = () => {
    setNewClaimant(null);
    setClaimant(null);
  };
  const handleAddClaimant = ({ name, participantId }) => {
    setNewClaimant({
      displayElem: <RemovableRadioLabel text={`${name}, Attorney`} onRemove={handleRemove} />,
      value: participantId,
      defaultPayeeCode: ''
    });
    setClaimant(participantId);
    setShowClaimantModal(false);
  };
  const handlePayeeCodeChange = (event) => setPayeeCode(event ? event.value : null);
  const shouldShowPayeeCode = () => {
    return formType !== 'appeal' && (benefitType === 'compensation' || benefitType === 'pension');
  };

  const hasRelationships = relationships.length > 0;
  const showClaimants = ['true', true].includes(veteranIsNotClaimant);

  const claimantOptions = () => {
    return (
      <div className="cf-claimant-options">
        <RadioField
          name="claimant-options"
          label={claimantLabel}
          strongLabel
          vertical
          options={radioOpts}
          onChange={setClaimant}
          value={claimant}
          errorMessage={claimantError}
        />

        {shouldShowPayeeCode() && (
          <SearchableDropdown
            name="cf-payee-code"
            strongLabel
            label="What is the payee code for this claimant?"
            placeholder="Select"
            options={isVeteranDeceased ? DECEASED_PAYEE_CODES : LIVING_PAYEE_CODES}
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
    setVeteranIsNotClaimant('true');
  }

  return (
    <div className="cf-different-claimant">
      <RadioField
        name="different-claimant-option"
        label="Is the claimant someone other than the Veteran?"
        strongLabel
        vertical
        options={veteranClaimantOptions}
        onChange={setVeteranIsNotClaimant}
        errorMessage={veteranIsNotClaimantError}
        value={veteranIsNotClaimant === null ? null : veteranIsNotClaimant.toString()}
      />

      {showClaimants && hasRelationships && claimantOptions()}
      {showClaimants && !hasRelationships && noClaimantsCopy}

      {allowAddClaimant && (
        <>
          <Button
            classNames={['usa-button-secondary', classes.button]}
            name="+ Add Claimant"
            id="button-addClaimant"
            onClick={openAddClaimantModal}
          />

          {showClaimantModal && (
            <AddClaimantModal onCancel={() => setShowClaimantModal(false)} onSubmit={handleAddClaimant} />
          )}
        </>
      )}
    </div>
  );
};

SelectClaimant.propTypes = {
  benefitType: PropTypes.string,
  formType: PropTypes.string,
  isVeteranDeceased: PropTypes.bool,
  veteranIsNotClaimant: PropTypes.oneOfType([PropTypes.string, PropTypes.bool]),
  veteranIsNotClaimantError: PropTypes.string,
  setVeteranIsNotClaimant: PropTypes.func,
  claimant: PropTypes.string,
  claimantError: PropTypes.string,
  setClaimant: PropTypes.func,
  relationships: PropTypes.array,
  payeeCode: PropTypes.string,
  payeeCodeError: PropTypes.string,
  setPayeeCode: PropTypes.func
};

export default SelectClaimant;
