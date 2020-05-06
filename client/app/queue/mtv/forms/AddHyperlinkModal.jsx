import React, { useState, useMemo } from 'react';
import PropTypes from 'prop-types';

import Modal from '../../../components/Modal';
import {
  MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_TITLE,
  MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_INSTRUCTIONS
} from '../../../../COPY';
import TextField from '../../../components/TextField';

export const AddHyperlinkModal = ({ onSubmit, onCancel }) => {
  const [type, setType] = useState('');
  const [link, setLink] = useState('');
  const inValid = useMemo(() => !type || !link, [type, link]);

  const buttons = [
    {
      classNames: ['cf-modal-link', 'cf-btn-link'],
      name: 'Cancel',
      onClick: onCancel
    },
    {
      classNames: ['usa-button', 'usa-button-primary'],
      name: 'Save',
      onClick: () => onSubmit({ type, link }),
      disabled: inValid
    }
  ];

  return (
    <Modal buttons={buttons} title={MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_TITLE} closeHandler={onCancel}>
      <div className="cf-margin-bottom-2rem">{MOTIONS_ATTORNEY_REVIEW_MTV_HYPERLINK_MODAL_INSTRUCTIONS}</div>

      <TextField
        name="type"
        label="Insert type of the document"
        value={type}
        onChange={(val) => setType(val)}
        strongLabel
        placeholder="e.g. Veteran's Medical Record"
        className={['mtv-review-hyperlink', 'cf-margin-bottom-2rem']}
      />

      <TextField
        name="link"
        label="Insert hyperlink to the document"
        value={link}
        onChange={(val) => setLink(val)}
        strongLabel
        className={['mtv-review-hyperlink', 'cf-margin-bottom-2rem']}
      />
    </Modal>
  );
};

AddHyperlinkModal.propTypes = {
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func
};
