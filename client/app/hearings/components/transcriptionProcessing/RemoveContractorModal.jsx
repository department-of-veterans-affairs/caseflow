import React, { useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import Dropdown from '../../../components/Dropdown';
// import COPY from '../../../../COPY';
import ApiUtil from '../../../util/ApiUtil';

export const RemoveContractorModal = ({ onCancel, onConfirm, title, contractors }) => {
  const [selectedContractorId, setSelectedContractorId] = useState(null);

  const removeContractor = (contractorId) => {
    console.log("removeContractor called", contractorId);
    const data = { id: contractorId };

    ApiUtil.delete(`/hearings/find_by_contractor/${data.id}`).then(() => {
      onConfirm({
        title: "Remove Success",
        message: `Contractor with ID ${data.id} was removed successfully`,
        type: "success",
      });
    });
  };

  const handleConfirm = () => {
    if (selectedContractorId) {
      removeContractor(selectedContractorId);
    }
  };

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
          name: "Remove",
          onClick: handleConfirm,
        },
      ]}
      closeHandler={onCancel}
      id="custom-contractor-modal"
    >
      <p>"Form Description"</p>
      <Dropdown
        name="contractors"
        options={dropdownOptions}
        onChange={handleDropdownChange}
        defaultText="Select a contractor"
      />
    </Modal>
  );
};

RemoveContractorModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  title: PropTypes.string,
  contractors: PropTypes.array,
};
