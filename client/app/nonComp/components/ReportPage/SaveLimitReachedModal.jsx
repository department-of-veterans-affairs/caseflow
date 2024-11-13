import React from 'react';
import Modal from 'app/components/Modal';
import COPY from 'app/../COPY';
import PropTypes from 'prop-types';

export const SaveLimitReachedModal = ({ setShowLimitModal }) => {

  const handleCancel = () => {
    setShowLimitModal(false);
  };

  const submitForm = () => {
    // console.log('this will be updated in next ticket');
  };

  const handleRedirect = () => {
    // this will be handle in another ticket;
  };

  return (
    <Modal title={COPY.SAVE_LIMIT_REACH_TITLE}
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: handleCancel
        },
        { classNames: ['usa-button', 'cf_add_margin'],
          name: 'Delete',
          onClick: submitForm
        },
        { classNames: ['usa-button', 'usa-button-secondary'],
          name: 'View saved searches',
          onClick: handleRedirect
        }
      ]}
      closeHandler={handleCancel}
    >
      <p>{COPY.SAVE_LIMIT_REACH_MESSAGE}</p>
    </Modal>);
};

SaveLimitReachedModal.propTypes = {
  setShowLimitModal: PropTypes.func.isRequired
};

export default SaveLimitReachedModal;
