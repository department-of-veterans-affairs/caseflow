import React from 'react';
import PropTypes from 'prop-types';
import Modal from '../../../components/Modal';
import COPY from '../../../../COPY';

const PackageFilesModal = ({ onCancel }) => {
  return (
    <Modal
      title="Package Files"
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: COPY.TRANSCRIPTION_SETTINGS_CANCEL,
          onClick: onCancel
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: COPY.TRANSCRIPTION_TABLE_PACKAGE_FILE,
          onClick: onCancel,
        },
      ]}
      closeHandler={onCancel}
    />);
};

PackageFilesModal.propTypes = {
  onCancel: PropTypes.func
};

export default PackageFilesModal;
