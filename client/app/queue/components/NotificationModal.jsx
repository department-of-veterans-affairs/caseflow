import React from 'react'
import Modal from '../../components/Modal'
import Button from '../../components/Button'
import PropTypes from 'prop-types'

const NotificationModal = ({eventType, notificationContent}) => {
  return (
    <div>
        <Modal 
        title={eventType} 
        cancelButton={
            <Button classNames={['cf-btn-link']}>
                Close
            </Button>
            }
        >
            {notificationContent}
        </Modal>
    </div>
  )
}

NotificationModal.propTypes = {
    eventType: PropTypes.string,
    notificationContent: PropTypes.string,
}

export default NotificationModal