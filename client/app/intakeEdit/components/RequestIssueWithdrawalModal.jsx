import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../components/Modal';

// To be completed in APPEALS-39446
export const RequestIssueWithdrawalModal = (props) => {
  return (
    <Modal
      title="Request issue withdrawal"
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

RequestIssueWithdrawalModal.propTypes = {
  onCancel: PropTypes.func,
};

export default RequestIssueWithdrawalModal;
