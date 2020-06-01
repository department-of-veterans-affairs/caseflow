import React, { useState, useMemo, useEffect } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import { ADD_CLAIMANT_MODAL_TITLE, ADD_CLAIMANT_MODAL_DESCRIPTION } from '../../../COPY';
import ReactMarkdown from 'react-markdown';
import SearchableDropdown from '../../components/SearchableDropdown';

const sampleData = [
  { id: 1, fullName: 'Attorney 1', cssId: 'CSS_ID_1', participantId: 1 },
  { id: 2, fullName: 'Attorney 2', cssId: 'CSS_ID_2', participantId: 2 },
  { id: 3, fullName: 'Attorney 3', cssId: 'CSS_ID_3', participantId: 3 }
];

export const AddClaimantModal = ({ onCancel, onSubmit }) => {
  const [claimant, setClaimant] = useState(null);
  const [searchResults] = useState(sampleData);
  const [dropdownOpts, setDropdownOpts] = useState([]);
  const isInvalid = useMemo(() => !claimant, [claimant]);
  const handleChange = (value) => setClaimant(value);

  useEffect(() => {
    setDropdownOpts(
      searchResults.map((item) => ({
        label: item.fullName,
        value: item.participantId
      }))
    );
  }, [searchResults]);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Add this claimant',
      onClick: () => onSubmit({ participantId: claimant.value }),
      disabled: isInvalid
    }
  ];

  return (
    <Modal title={ADD_CLAIMANT_MODAL_TITLE} buttons={buttons} closeHandler={onCancel}>
      <div>
        <ReactMarkdown source={ADD_CLAIMANT_MODAL_DESCRIPTION} />
      </div>
      <SearchableDropdown label="Claimant's name" options={dropdownOpts} onChange={handleChange} value={claimant} />
    </Modal>
  );
};

AddClaimantModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
