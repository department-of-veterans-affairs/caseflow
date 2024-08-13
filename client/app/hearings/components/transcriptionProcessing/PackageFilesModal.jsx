import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import { RadioField } from '../../../components/RadioField';
import { SearchableDropdown } from '../../../components/SearchableDropdown';
import ApiUtil from 'app/util/ApiUtil';
import { useHistory } from 'react-router';

const PackageFilesModal = ({ onCancel, contractors, selectedFiles }) => {
  const [transcription, setTranscription] = useState({ task_id: '' });
  const [, setReturnDateValue] = useState('');
  const [, setContractorId] = useState('');
  let history = useHistory();

  /**
   * Grabs the taskId
  */
  const getTranscriptionTaskId = () => {
    ApiUtil.get('/hearings/transcriptions/next_transcription').
      // eslint-disable-next-line camelcase
      then((response) => setTranscription(response.body));
  };

  /**
   * Generates the work order number
   * @param {number} taskId - The task id for the transcription
   * @return {string} The generated work order number
   */
  const generateWorkOrder = (taskId) => {
    const taskIdString = taskId.toString();
    const year = new Date().getFullYear().
      toString();

    let numberOfDigits = taskId.toString().length;
    let sequencer;
    let firstSet;

    if (numberOfDigits > 5) {
      firstSet = year.substring(2) + taskIdString.substring(0, 2);
      sequencer = taskIdString.substring(2);
    } else if (numberOfDigits === 5) {
      firstSet = `${year.substring(2)}0${taskIdString.substring(0, 1)}`;
      sequencer = taskIdString.substring(1);
    } else {
      firstSet = year;
      sequencer = '0'.repeat(4 - numberOfDigits) + taskId;
    }

    return `BVA-${firstSet}-${sequencer}`;
  };

  // Renders the work order number
  const renderWorkOrder = () => {
    return (
      <div>
        <strong>Work Order</strong>
        <p>{transcription.task_id && generateWorkOrder(transcription.task_id)}</p>
      </div>
    );
  };

  /**
   * Calculates the expected return date for the radio buttons
   * @params {number} days - Amount of days from today
   * @returns {string} The formatted expected return date
   */
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

  /**
   * Creates the radio button options
   * @returns {object} The radio button options
   */
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

  /**
   * Creates the contractor options for dropdown
   * @returns {object} The contractor option
   */
  const contractorOptions = () => {
    return contractors.map((contractor) => {
      return {
        label: contractor.name,
        value: contractor.id
      };
    });
  };

  // Renders the contractors dropdown
  const renderContractors = () => {
    return <SearchableDropdown
      name=<strong>Contractor</strong>
      options={contractorOptions()}
      onChange={(option) => setContractorId(option.value)}
    />;
  };

  // Renders the radio field for return date
  const renderReturnDateSection = () => {
    return (
      <RadioField
        name="returnDateRadioField"
        label=<strong>Return date</strong>
        options={returnDateOptions()}
        onChange={(value) => setReturnDateValue(value)}
      />
    );
  };

  // Temporary function for rolling over to next transcription for testing
  const packageFiles = (id, taskId) => {
    ApiUtil.put('/hearings/transcriptions/package_files', { data: { id, task_id: taskId } }).
      then(() => onCancel());
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
          onClick: () => history.push('/confirm_work_order', { selectedFiles })
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
  contractors: PropTypes.object,
  selectedFiles: PropTypes.arrayOf(PropTypes.object)
};

export default PackageFilesModal;
