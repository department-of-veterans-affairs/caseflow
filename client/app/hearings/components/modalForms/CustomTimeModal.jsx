import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';

export const CustomTimeModal = ({ roTimezone }) => {
  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: () => {}
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Create time slot',
      onClick: () => {}
    },
  ];

  return (
    <Modal title="Create a custom time slot" buttons={buttons}>
      <div>stuff {roTimezone}</div>
    </Modal>
  );
};

CustomTimeModal.propTypes = {
  roTimezone: PropTypes.string
};
