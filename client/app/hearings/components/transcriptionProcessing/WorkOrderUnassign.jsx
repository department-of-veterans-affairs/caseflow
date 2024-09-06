import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';
import ApiUtil from 'app/util/ApiUtil';

const WorkOrderUnassign = ({ onClose, workOrderNumber }) => {
  const unassignWorkOrder = (orderNumber) => {
    const cleanedWorkOrderNumber = orderNumber.replace('BVA', '');
    const data = { task_number: cleanedWorkOrderNumber };
    const url = '/hearings/transcription_work_order/unassigning_work_order';

    ApiUtil.post(url, { data }).
      then((response) => {
        if (response.body.success) {
          onClose();
        }
      });
  };

  const handleConfirm = () => {
    unassignWorkOrder(workOrderNumber);
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
            onClick: handleConfirm
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
  workOrderNumber: PropTypes.string.isRequired,
};

export default WorkOrderUnassign;

