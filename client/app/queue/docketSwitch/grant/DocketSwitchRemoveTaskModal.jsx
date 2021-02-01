import Modal from '../../../components/Modal';
import React from 'react';
import {
  DOCKET_SWITCH_GRANTED_MODAL_TITLE,
  DOCKET_SWITCH_GRANTED_MODAL_INSTRUCTION,
  MODAL_CANCEL_BUTTON,
  MODAL_CONFIRM_BUTTON
} from 'app/../COPY';
import PropTypes from 'prop-types';
import { sprintf } from 'sprintf-js';
import ReactMarkdown from 'react-markdown';

export const DocketSwitchRemoveTaskConfirmationModal = ({ onConfirm, onCancel, taskLabel }) => (
  <div>
    <Modal
      title={DOCKET_SWITCH_GRANTED_MODAL_TITLE}
      closeHandler={onCancel}
      buttons={[
        { classNames: ['cf-modal-link', 'cf-btn-link'],
          name: MODAL_CANCEL_BUTTON,
          onClick: onCancel,
        },
        {
          classNames: ['usa-button', 'usa-button-primary'],
          name: MODAL_CONFIRM_BUTTON,
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

DocketSwitchRemoveTaskConfirmationModal.propTypes = {
  onCancel: PropTypes.func,
  onConfirm: PropTypes.func,
  taskLabel: PropTypes.string
};

export default DocketSwitchRemoveTaskConfirmationModal;

