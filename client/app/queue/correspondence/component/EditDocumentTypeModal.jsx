import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { sprintf } from 'sprintf-js';

import COPY from '../../../../COPY';
// import { onReceiveAmaTasks } from '../../queue/QueueActions';
import { showErrorMessage, showSuccessMessage } from '../../uiReducer/uiActions';

// import ApiUtil from '../../util/ApiUtil';
import Modal from '../../../components/Modal';
import Button from '../../../components/Button';

export const EditDocumentTypeModal = ({
  document,
  onCancel,

}) => {
  const [loading] = useState(false);
  // const [unscheduledNotes, setUnscheduledNotes] = useState(task?.unscheduledHearingNotes?.notes);

  const disable = true;


  // eslint-disable-next-line no-empty-function
  const submit = async () => { };

  return (
    <Modal
      title= {sprintf(COPY.TITLE_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}
      closeHandler={onCancel}
      confirmButton={<Button disabled={disable} onClick={submit}>Save</Button>}
      cancelButton={<Button linkStyling disabled={loading} onClick={onCancel}>Cancel</Button>}
    >
      <p>
        <div>{sprintf(COPY.TEXT_MODAL_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}</div>
      </p>
      <p>
        <div style={{ fontWeight: 'bold' }}>{sprintf(COPY.ORIGINAL_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}</div>
        <div>{document.documentName}</div>
      </p>

      <p>
        <div>{sprintf(COPY.NEW_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}</div>
        <div>{sprintf(COPY.ORIGINAL_DOC_EDIT_DOCUMENT_TYPE_CORRESPONDENCE)}</div>
      </p>

    </Modal>
  );
};

EditDocumentTypeModal.propTypes = {
  modalState: PropTypes.bool,
  onCancel: PropTypes.func,
  document: PropTypes.string
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      showErrorMessage,
      showSuccessMessage
    },
    dispatch
  );

export default connect(null, mapDispatchToProps)(EditDocumentTypeModal);
