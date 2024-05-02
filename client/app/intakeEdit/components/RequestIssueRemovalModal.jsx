import React from 'react';
import PropTypes from 'prop-types';
import Modal from 'app/components/Modal';

// To be completed in APPEALS-39446
export const RequestIssueRemovalModal = (props) => {
  return (
    <Modal
      title="Request issue removal"
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

RequestIssueRemovalModal.propTypes = {
  onCancel: PropTypes.func,
};

export default RequestIssueRemovalModal;
