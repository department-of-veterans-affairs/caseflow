/* eslint-disable no-undefined */
import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import COPY from '../../../COPY';

const CancelCavcDashboardChangeModal = (props) => {
  const { history, closeHandler } = props;

  const confirm = () => {
    history.goBack();
  };

  return (
    <Modal
      title={COPY.CANCEL_CAVC_DASHBOARD_CHANGE_MODAL_HEADER}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: closeHandler,
        },
        {
          classNames: ['usa-button'],
          name: COPY.CONTINUE_BUTTON_TEXT,
          onClick: confirm,
        }
      ]}
      closeHandler={closeHandler}
    >
      <p>{COPY.CANCEL_CAVC_DASHBOARD_CHANGE_MODAL_BODY}</p>
    </Modal>
  );
};

CancelCavcDashboardChangeModal.propTypes = {
  closeHandler: PropTypes.func,
  history: PropTypes.object
};

export default CancelCavcDashboardChangeModal;
