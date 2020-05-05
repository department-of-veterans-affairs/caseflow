import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';
import { ADD_CLAIMANT_MODAL_TITLE, ADD_CLAIMANT_MODAL_DESCRIPTION } from '../../../COPY';
import ReactMarkdown from 'react-markdown';
import SearchableDropdown from '../../components/SearchableDropdown';

const tempOpts = [
  { label: 'Attorney 1', value: 'CSS_ID_1' },
  { label: 'Attorney 2', value: 'CSS_ID_2' },
  { label: 'Attorney 3', value: 'CSS_ID_3' }
];

export const AddClaimantModal = ({ onCancel, onSubmit }) => {
  const [claimant, setClaimant] = useState(null);
  const inValid = useMemo(() => !claimant, [claimant]);
  const handleChange = (value) => setClaimant(value);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Add this claimant',
      onClick: () => onSubmit({ claimant }),
      disabled: inValid
    }
  ];

  return (
    <Modal title={ADD_CLAIMANT_MODAL_TITLE} buttons={buttons}>
      <div>
        <ReactMarkdown source={ADD_CLAIMANT_MODAL_DESCRIPTION} />
      </div>
      <SearchableDropdown label="Claimant's name" options={tempOpts} onChange={handleChange} value={claimant} />
    </Modal>
  );
};

AddClaimantModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
