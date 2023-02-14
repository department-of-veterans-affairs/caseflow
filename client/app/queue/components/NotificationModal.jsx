import React from 'react';
import Modal from '../../components/Modal';
import Button from '../../components/Button';
import PropTypes from 'prop-types';
import COPY from '../../../COPY';

const NotificationModal = ({ eventType, notificationContent, closeNotificationModal }) => {
  return (
    <div>
      <Modal
        title={eventType}
        confirmButton={
          <Button onClick={closeNotificationModal} classNames={['usa-button-primary']}>
                Close
          </Button>
        }
        closeHandler={closeNotificationModal}
      >
        <span>{COPY.NOTIFICATION_CONTENT_MESSAGE}</span>
        <br /><br />
        <span data-testid="body-content">"{notificationContent}"</span>
      </Modal>
    </div>
  );
};

NotificationModal.propTypes = {
  eventType: PropTypes.string,
  notificationContent: PropTypes.string,
  closeNotificationModal: PropTypes.func,
};

export default NotificationModal;
