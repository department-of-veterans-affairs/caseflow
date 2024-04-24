import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';

// To be completed in APPEALS-39446
export const RequestIssueAdditionModal = (props) => {
  return (
    <Modal
      title="Request issue addition"
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
          name: 'Cancel',
          onClick: props.onCancel
        },
      ]}
      closeHandler={props.onCancel}
    >
      <div></div>
    </Modal>
  );
};

RequestIssueAdditionModal.propTypes = {
  onCancel: PropTypes.func,
};

export default RequestIssueAdditionModal;
