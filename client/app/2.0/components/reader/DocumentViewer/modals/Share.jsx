// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import Modal from 'app/components/Modal';
import CopyTextButton from 'app/components/CopyTextButton';

/**
 * PDF File Component
 * @param {Object} props
 */
export const ShareComment = ({ commentId, closeShareModal, show }) => show && (
  <Modal
    title="Share Comment"
    closeHandler={closeShareModal}
    buttons={[
      {
        classNames: ['usa-button', 'usa-button-secondary'],
        name: 'Close',
        onClick: closeShareModal
      }
    ]}
  >
    <CopyTextButton
      label="Link to annotation"
      text={`${location.origin}${location.pathname}?annotation=${commentId}`}
    />
  </Modal>
);

ShareComment.propTypes = {
  show: PropTypes.bool,
  commentId: PropTypes.number,
  closeShareModal: PropTypes.func
};
