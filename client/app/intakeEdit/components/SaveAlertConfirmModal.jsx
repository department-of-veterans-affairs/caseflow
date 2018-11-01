import React from 'react';

import Modal from '../../components/Modal';

class SaveAlertConfirmModal extends React.PureComponent {
  render() {
    return <span className="intake-modal">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: this.props.onClose
          },
          { classNames: ['usa-button-red', 'confirm'],
            name: 'Yes, save',
            onClick: this.props.onConfirm
          }
        ]}
        visible
        closeHandler={this.props.onClose}
        title={this.props.title}
      >
        {this.props.children}
      </Modal>
    </span>;
  }
}

export default SaveAlertConfirmModal;
