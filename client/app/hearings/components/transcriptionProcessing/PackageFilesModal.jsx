import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import { RadioField } from '../../../components/RadioField';
import { SearchableDropdown } from '../../../components/SearchableDropdown';
import ApiUtil from 'app/util/ApiUtil';

const PackageFilesModal = ({ onCancel, contractors }) => {
  const [transcriptionTaskId, setTranscriptionTaskId] = useState(0);
  const [returnDateOption, setReturnDateOption] = useState(null);

  const getTranscriptionTaskId = () => {
    ApiUtil.get('/hearings/transcriptions/next_transcription_task_id').
      // eslint-disable-next-line camelcase
      then((response) => setTranscriptionTaskId(response.body?.task_id));
  };

  const generateWorkOrder = (taskId) => {
    const taskIdString = taskId.toString();
    const year = new Date().getFullYear().
      toString();

    let numberOfDigits = taskId.toString().length;
    let sequencer;
    let firstSet;

    if (numberOfDigits > 5) {
      firstSet = year.substring(0, 2) + taskIdString.substring(0, 2);
      sequencer = taskIdString.substring(2);
    } else if (numberOfDigits === 5) {
      firstSet = `${year.substring(0, 2)}0${taskIdString.substring(0, 1)}`;
      sequencer = taskIdString.substring(1);
    } else {
      firstSet = year;
      sequencer = taskId;
    }

    return `BVA-${firstSet}-${sequencer}`;
  };

  const renderWorkOrder = () => {
    return (
      <div>
        <strong>Work Order</strong>
        <p>{transcriptionTaskId && generateWorkOrder(transcriptionTaskId)}</p>
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
    const fifteenDayReturnDate = calculateReturnDate(15);

    return [
      {
        displayText: `Return in 15 days (${fifteenDayReturnDate})`,
        value: fifteenDayReturnDate
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
        onChange={(value) => setReturnDateOption(value)}
      />
    );
  };

  useEffect(() => {
    getTranscriptionTaskId();
  }, []);

  return (
    <Modal
      title="Package files"
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
