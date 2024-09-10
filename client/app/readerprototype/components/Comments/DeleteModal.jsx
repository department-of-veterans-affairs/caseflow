import PropTypes from 'prop-types';
import React from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Modal from '../../../components/Modal';
import { closeAnnotationDeleteModal, deleteAnnotation } from '../../../reader/AnnotationLayer/AnnotationActions';
import { modalInfoSelector } from '../../selectors';

const DeleteModal = ({ documentId }) => {
  const dispatch = useDispatch();
  const { deleteAnnotationModalIsOpenFor } = useSelector(modalInfoSelector);

  if (!deleteAnnotationModalIsOpenFor) {
    return null;
  }

  return (
    <Modal
      buttons={[
        {
          classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: () => dispatch(closeAnnotationDeleteModal()),
        },
        {
          classNames: ['usa-button', 'usa-button-secondary'],
          name: 'Confirm delete',
          onClick: () => dispatch(deleteAnnotation(documentId, deleteAnnotationModalIsOpenFor)),
        },
      ]}
      closeHandler={() => dispatch(closeAnnotationDeleteModal())}
      title="Delete Comment"
    >
      Are you sure you want to delete this comment?
    </Modal>
  );
};

DeleteModal.propTypes = {
  documentId: PropTypes.number,
};

export default DeleteModal;
