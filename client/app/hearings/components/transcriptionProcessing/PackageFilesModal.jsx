import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import { RadioField } from '../../../components/RadioField';
import { SearchableDropdown } from '../../../components/SearchableDropdown';
import ApiUtil from 'app/util/ApiUtil';
import { useHistory } from 'react-router';

const PackageFilesModal = ({ onCancel, contractors, returnDates, selectedFiles }) => {
  const [returnDateValue, setReturnDateValue] = useState('');
  const [contractor, setContractor] = useState({ id: '0', name: '' });
  const [workOrder, setWorkOrder] = useState('');
  let history = useHistory();

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

    setWorkOrder(`BVA-${firstSet}-${sequencer}`);
  };

  /**
   * Grabs the taskId
  */
  const getTranscriptionTaskId = () => {
    ApiUtil.get('/hearings/transcriptions/next_transcription').
      // eslint-disable-next-line camelcase
      then((response) => {
        generateWorkOrder(response.body.task_id);
      });
  };

  // Renders the work order number
  const renderWorkOrder = () => {
    return (
      <div>
        <strong>Work Order</strong>
        <p>{workOrder}</p>
      </div>
    );
  };

  /**
   * Creates the radio button options
   * @returns {object} The radio button options
   */
  const returnDateOptions = () => {
    const fifteenDayReturnDate = returnDates[0];
    const fiveDayReturnDate = returnDates[1];

    return [
      {
        displayText: `Return in 15 days (${fifteenDayReturnDate})`,
        value: fifteenDayReturnDate
      },
      {
        displayText: 'Expedite (Maximum of 5 days)',
        value: fiveDayReturnDate
      }
    ];
  };

  /**
   * Creates the contractor options for dropdown
   * @returns {object} The contractor option
   */
  const contractorOptions = () => {
    return contractors.map((option) => {
      return {
        label: option.name,
        value: option.id
      };
    });
  };

  // Renders the contractors dropdown
  const renderContractors = () => {
    return <SearchableDropdown
      name=<strong>Contractor</strong>
      options={contractorOptions()}
      onChange={(option) => setContractor({ id: option.value, name: option.label })}
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
          disabled: !(workOrder && returnDateValue && contractor.name),
          onClick: () => history.push('/confirm_work_order', { workOrder, selectedFiles, returnDateValue, contractor })
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
  returnDates: PropTypes.array,
  selectedFiles: PropTypes.arrayOf(PropTypes.object)
};

export default PackageFilesModal;
