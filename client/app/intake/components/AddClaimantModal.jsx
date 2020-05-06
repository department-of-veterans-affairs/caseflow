import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';
import { debounce } from 'lodash';
import Modal from '../../components/Modal';
import { ADD_CLAIMANT_MODAL_TITLE, ADD_CLAIMANT_MODAL_DESCRIPTION } from '../../../COPY';
import ReactMarkdown from 'react-markdown';
import SearchableDropdown from '../../components/SearchableDropdown';

const sampleData = [
  { id: 1, fullName: 'Attorney 1', cssId: 'CSS_ID_1', participantId: 1 },
  { id: 2, fullName: 'Attorney 2', cssId: 'CSS_ID_2', participantId: 2 },
  { id: 3, fullName: 'Attorney 3', cssId: 'CSS_ID_3', participantId: 3 }
];

const fetchAttorneys = async (search = '') => {
  // TODO: replace with actual API call
  return await new Promise((resolve, reject) => {
    setTimeout(() => {
      const res = sampleData.filter((item) => item.fullName.toLowerCase().includes(search));

      return res ? resolve(res) : reject('no records found');
    }, 1500);
  });
};
const debouncedFetch = debounce(fetchAttorneys, 250, { leading: true, trailing: false });
const getClaimantOpts = async (search = '') => {
  // Enforce minimum search length (we'll simply return empty array rather than throw error)
  const options =
    search.length < 3 ?
      [] :
      (await debouncedFetch(search)).map((item) => ({
        label: item.fullName,
        value: item.participantId
      }));

  return { options };
};

export const AddClaimantModal = ({ onCancel, onSubmit }) => {
  const [claimant, setClaimant] = useState(null);
  const isInvalid = useMemo(() => !claimant, [claimant]);
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
      onClick: () => onSubmit({ participantId: claimant.value }),
      disabled: isInvalid
    }
  ];

  return (
    <Modal title={ADD_CLAIMANT_MODAL_TITLE} buttons={buttons} closeHandler={onCancel}>
      <div>
        <ReactMarkdown source={ADD_CLAIMANT_MODAL_DESCRIPTION} />
      </div>
      <SearchableDropdown
        name="search"
        label="Claimant's name"
        onChange={handleChange}
        value={claimant}
        async={getClaimantOpts}
        options={[]}
        debounce={250}
      />
    </Modal>
  );
};

AddClaimantModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
