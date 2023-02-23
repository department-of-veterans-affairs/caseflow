/* eslint-disable no-undefined */
import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import COPY from '../../../COPY';

const RemoveCavcDashboardIssueModal = (props) => {
  const { closeHandler, submitHandler } = props;

  return (
    <Modal
      title={COPY.REMOVE_CAVC_DASHBOARD_ISSUE_MODAL_TITLE}
      buttons={[
        {
          classNames: ['usa-button', 'cf-btn-link'],
          name: COPY.MODAL_CANCEL_BUTTON,
          onClick: closeHandler,
        },
        {
          classNames: ['usa-button'],
          name: COPY.MODAL_REMOVE_BUTTON,
          onClick: submitHandler,
        }
      ]}
      closeHandler={closeHandler}
    >
      <p>{COPY.CAVC_DASHBOARD_REMOVE_ISSUE_UPPER_TEXT}</p>
      <p>{COPY.CAVC_DASHBOARD_REMOVE_ISSUE_LOWER_TEXT}</p>
    </Modal>
  );
};

RemoveCavcDashboardIssueModal.propTypes = {
  closeHandler: PropTypes.func,
  submitHandler: PropTypes.func
};

export default RemoveCavcDashboardIssueModal;
