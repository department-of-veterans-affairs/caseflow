// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import Modal from 'app/components/Modal';

/**
 * Delete Comment Modal Component
 * @param {Object} props
 */
export const DeleteComment = ({ closeDeleteModal, removeComment, pendingDeletion, show, deleteCommentId }) => show && (
  <Modal
    title="Delete Comment"
    closeHandler={closeDeleteModal}
    buttons={[
      {
        classNames: ['cf-modal-link', 'cf-btn-link'],
        name: 'Cancel',
        onClick: closeDeleteModal,
        disabled: pendingDeletion
      },
      {
        id: '#Delete-Comment-button',
        classNames: ['usa-button', 'usa-button-secondary'],
        name: 'Confirm delete',
        onClick: removeComment,
        disabled: pendingDeletion
      }
    ]}
  >
  Are you sure you want to delete this comment?
  </Modal>
);

DeleteComment.propTypes = {
  deleteCommentId: PropTypes.number,
  show: PropTypes.bool,
  pendingDeletion: PropTypes.bool,
  removeComment: PropTypes.func,
  closeDeleteModal: PropTypes.func
};
