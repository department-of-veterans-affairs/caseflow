import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import Dropdown from '../../../components/Dropdown';

export const RemoveContractorModal = ({ onCancel, title, onConfirm, contractors }) => {
  const [selectedContractorId, setSelectedContractorId] = useState(null);

  const handleDropdownChange = (contractorId) => {
    setSelectedContractorId(contractorId);
  };

  const dropdownOptions = contractors.map((contractor) => ({
    value: contractor.id,
    displayText: contractor.name,
  }));

  return (
    <Modal
      title={title}
      buttons={[
        {
          classNames: ["cf-modal-link", "cf-btn-link"],
          name: "Cancel",
          onClick: onCancel,
        },
        {
          classNames: ["usa-button", "usa-button-primary"],
          name: "Confirm",
          onClick: () => {
            onConfirm(selectedContractorId).then(onCancel);
          },
        }
      ]}
      closeHandler={onCancel}
      id="custom-contractor-modal"
    >
      <p>
        This will permanently remove this contractor from the list of assignable
        contractors.
      </p>
      <Dropdown
        key={contractors.length}
        name="Contractor"
        options={dropdownOptions}
        onChange={handleDropdownChange}
        defaultText="Select a contractor"
        value={selectedContractorId}
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

// Provide default props
RemoveContractorModal.defaultProps = {
  onCancel: () => {},
  contractors: [],
};
