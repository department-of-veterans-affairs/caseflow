import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';

const WorkOrderUnassign = ({ onClose, workOrderNumber, id }) => {
  const renderContent = () => (
    <div>
      <h1>#{workOrderNumber}</h1>
      <p>
        Unassigning this order will return all appeals back to the
        Unassigned Transcription queue.
      </p>
      <p>
        <strong>
          Please ensure that all hearing files are removed from the
          contractors's box.com folder.
        </strong>
      </p>
    </div>
  );

  return (
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
          onClick: () => { /* Add your unassign order logic here */ }
        },
      ]}
      closeHandler={onClose}
    >
      {renderContent()}
    </Modal>
  );
};

WorkOrderUnassign.propTypes = {
  onClose: PropTypes.func.isRequired,
  workOrderNumber: PropTypes.number.isRequired,
  id: PropTypes.number.isRequired,
};

export default WorkOrderUnassign;
