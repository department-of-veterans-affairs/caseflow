import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import SearchableDropdown from '../../../components/SearchableDropdown';
import COPY from '../../../../COPY';

export const RemoveContractorModal = ({ onCancel, title, onConfirm, contractors }) => {
  const [selectedContractorId, setSelectedContractorId] = useState(null);

  const handleDropdownChange = (selectedOption) => {
    setSelectedContractorId(selectedOption ? selectedOption.value : null);
  };

  const dropdownOptions = contractors.map((contractor) => ({
    value: contractor.id,
    label: contractor.name,
  }));

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ['cf-modal-link", "cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: onCancel,
        },
        {
          classNames: ['usa-button", "usa-button-primary'],
          name: COPY.MODAL_CONFIRM_BUTTON,
          onClick: () => {
            onConfirm(selectedContractorId).then(onCancel);
          },
          disabled: !selectedContractorId,
        },
      ]}
      closeHandler={onCancel}
      id="custom-contractor-modal"
    >
      <p>
        This will permanently remove this contractor from the list of assignable
        contractors.
      </p>
      <SearchableDropdown
        name="Contractors"
        label="Contractor"
        value={
          dropdownOptions.find(
            (option) => option.value === selectedContractorId
          ) || null
        }
        onChange={handleDropdownChange}
        options={dropdownOptions}
      />
    </Modal>
  );
};

RemoveContractorModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func.isRequired,
  title: PropTypes.string,
  contractors: PropTypes.array,
};

RemoveContractorModal.defaultProps = {
  contractors: [],
};
