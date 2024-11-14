import PropTypes from 'prop-types';
import React from 'react';

import Modal from 'app/components/Modal';
import COPY from 'app/../COPY';
import Button from 'app/components/Button';

import { useDispatch, useSelector } from 'react-redux';
import { deleteSearch } from 'app/nonComp/actions/savedSearchSlice';

const DeleteModal = ({ setShowDeleteModal }) => {
  const businessLineUrl = useSelector((state) => state.nonComp.businessLineUrl);
  const selectedSearch = useSelector((state) => state.savedSearch.selectedSearch);
  const dispatch = useDispatch();

  const handleDelete = () => {
    dispatch(deleteSearch({ organizationUrl: businessLineUrl, data: selectedSearch }));
    setShowDeleteModal(false);
  };

  const deleteSelectFragment = () => {
    return <>
      <li>
        <b>{selectedSearch.name}</b>
      </li>
    </>;
  };

  return (
    <Modal
      title="Delete Search"
      icon="warning"
      closeHandler={() => setShowDeleteModal(false)}
      confirmButton={<Button id="delete-search" onClick={handleDelete} >Delete</Button>}
      cancelButton={
        <Button
          id="cancel"
          classNames={['cf-modal-link', 'cf-btn-link']}
          onClick={() => setShowDeleteModal(false)}>
          Cancel
        </Button>
      }
    >
      {COPY.DELETE_SEARCH_DESCRIPTION}
      <ul>
        {deleteSelectFragment()}
      </ul>
    </Modal>
  );
};

DeleteModal.propTypes = {
  setShowDeleteModal: PropTypes.func.isRequired,
};

export default DeleteModal;
