import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import { RadioField } from '../../../components/RadioField';
import { SearchableDropdown } from '../../../components/SearchableDropdown';

const PackageFilesModal = ({ onCancel, contractors }) => {

  const renderWorkOrder = () => {
    return (
      <div>
        <strong>Work Order</strong>
        <p>#BVA20240001</p>
      </div>
    );
  };

  const calculateReturnDate = (days) => {
    const date = new Date();

    let dayofWeek = date.getDay();
    let daysRemaining = days;
    let totalDays = 0;

    while (daysRemaining > 0) {
      dayofWeek += 1;
      if (dayofWeek < 6) {
        daysRemaining -= 1;
        totalDays += 1;
      } else {
        totalDays += 2;
        dayofWeek = 0;
      }
    }

    date.setDate(date.getDate() + totalDays);

    return `${date.getMonth() + 1}/${date.getDate()}/${date.getFullYear()}`;

  };

  const returnDateOptions = () => {
    const returnDate = calculateReturnDate(15);

    return [
      {
        displayText: `Return in 15 days (${returnDate})`,
        value: returnDate
      },
      {
        displayText: 'Expedite (Maximum of 5 days)',
        value: calculateReturnDate(5)
      }
    ];
  };

  const contractorOptions = () => {
    return contractors.map((contractor) => {
      return {
        label: contractor.name,
        value: contractor.id
      };
    });
  };

  const renderContractors = () => {
    return <SearchableDropdown
      name=<strong>Contractor</strong>
      options={contractorOptions()}
    />;
  };

  const renderReturnDateSection = () => {
    return (
      <RadioField
        name="returnDateRadioField"
        label=<strong>Return date</strong>
        options={returnDateOptions()}
      />
    );
  };

  return (
    <Modal
      title="Package Files"
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: COPY.TRANSCRIPTION_SETTINGS_CANCEL,
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: COPY.TRANSCRIPTION_TABLE_PACKAGE_FILE,
          onClick: onCancel,
        },
      ]}
      closeHandler={onCancel}
    >
      {renderWorkOrder()}
      {renderReturnDateSection()}
      {renderContractors()}
    </Modal>);
};

PackageFilesModal.propTypes = {
  onCancel: PropTypes.func,
  contractors: PropTypes.object
};

export default PackageFilesModal;
