import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';

const WorkOrderUnassign = ({ onClose, workOrderNumber }) => {
  const handleUnassignOrder = async () => {
    try {
      const response = await ApiUtil.post(`/hearings/transcription_files/unassign_work_order/${workOrderNumber}`, {
        data: {}
      });

      if (!response.ok) {
        throw new Error('Network response was not ok');
      }

      const data = await response.json();
      console.log('Success:', data);
      // Handle success (e.g., show a success message, close the modal, etc.)
      onClose();
    } catch (error) {
      console.error('Error:', error);
      // Handle error (e.g., show an error message)
    }
  };

  const renderContent = () => (
    <div>
      <h1>#{workOrderNumber}</h1>
      <p>{COPY.TRANSCRIPTION_FILE_UNASSIGN_WORK_ORDER_MODAL_TEXT}</p>
      <p className="no-margin">
        <strong>
          {COPY.TRANSCRIPTION_FILE_UNASSIGN_WORK_ORDER_MODAL_BOLD_TEXT}
        </strong>
      </p>
    </div>
  );

  return (
    <>
      <style>
        {`
          .custom-modal #modal_id-title {
            margin-bottom: 0 !important;
          }
          .custom-modal .no-margin {
            margin-bottom: 0 !important;
          }
        `}
      </style>
      <Modal
        title="Unassign Work Order"
        buttons={[
          {
            classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Close',
            onClick: onClose
          },
          {
            classNames: ['usa-button', 'usa-button-primary'],
            name: 'Unassign order',
            onClick: handleUnassignOrder
          },
        ]}
        closeHandler={onClose}
        className="custom-modal"
      >
        {renderContent()}
      </Modal>
    </>
  );
};

WorkOrderUnassign.propTypes = {
  onClose: PropTypes.func.isRequired,
  workOrderNumber: PropTypes.number.isRequired,
};

export default WorkOrderUnassign;
