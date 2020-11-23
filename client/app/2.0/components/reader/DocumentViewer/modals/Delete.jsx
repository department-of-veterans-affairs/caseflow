// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import Modal from 'app/components/Modal';

/**
 * Delete Comment Modal Component
 * @param {Object} props
 */
export const DeleteComment = ({ closeDeleteModal, deleteComment, show }) => show && (
  <Modal
    title="Delete Comment"
    closeHandler={closeDeleteModal}
    buttons={[
      {
        classNames: ['cf-modal-link', 'cf-btn-link'],
        name: 'Cancel',
        onClick: closeDeleteModal
      },
      {
        classNames: ['usa-button', 'usa-button-secondary'],
        name: 'Confirm delete',
        onClick: deleteComment
      }
    ]}
  >
  Are you sure you want to delete this comment?
  </Modal>
);

DeleteComment.propTypes = {
  show: PropTypes.bool,
  deleteComment: PropTypes.func,
  closeDeleteModal: PropTypes.func
};
