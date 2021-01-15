import Modal from '../../../components/Modal';
import React from 'react';
import {
  DOCKET_SWITCH_GRANTED_MODAL_TITLE,
  DOCKET_SWITCH_GRANTED_MODAL_INSTRUCTION
} from 'app/../COPY';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import ReactMarkdown from 'react-markdown';

export const DocketSwitchAddTaskModal = ({ onConfirm, onSubmit, onCancel, taskLabel }) => (
  <div>
    <Modal
      title={DOCKET_SWITCH_GRANTED_MODAL_TITLE}
      closeHandler={onCancel}
      onSubmit={onSubmit}
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link'],
          name: 'Cancel',
          onClick: onCancel,
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: 'Confirm',
          onClick: onConfirm,
        }
      ]}
    >
      <div>
        <ReactMarkdown
          source={sprintf(DOCKET_SWITCH_GRANTED_MODAL_INSTRUCTION, taskLabel)} />
      </div>
    </Modal>
  </div>
);

DocketSwitchAddTaskModal.propTypes = {
  onSubmit: PropTypes.func,
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  taskLabel: PropTypes.string
};

export default DocketSwitchAddTaskModal;

