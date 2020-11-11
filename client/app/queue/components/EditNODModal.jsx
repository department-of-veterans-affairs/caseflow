import React from 'react';
import ReactMarkdown from 'react-markdown';
import Modal from 'app/components/Modal';
import DateSelector from 'app/components/DateSelector';
import COPY from 'app/../COPY';

export const EditNODModal = ({onCancel, onSubmit}) => {
  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: [],
      name: 'Submit',
      onClick: onSubmit
    }
  ];

  return (
    <Modal
      title={COPY.EDIT_NOD_MODAL_TITLE}
      onCancel={onCancel}
      closeHandler={onCancel}
      buttons={buttons}>
      <div>
        <ReactMarkdown source={COPY.EDIT_NOD_MODAL_DESCRIPTION} />
      </div>
      <DateSelector
        name={COPY.EDIT_NOD_DATE_DROPDOWN_LABEL}
        strongLabel
        type="date"
      />
    </Modal>
  );
};
