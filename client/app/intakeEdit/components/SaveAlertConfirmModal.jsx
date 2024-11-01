import React from 'react';
import PropTypes from 'prop-types';

import Modal from '../../components/Modal';
import COPY from 'app/../COPY';

class SaveAlertConfirmModal extends React.PureComponent {
  render() {
    const {
      buttonClassNames
    } = this.props;

    return <span className="intake-modal">
      <Modal
        buttons={[
          { classNames: ['cf-modal-link', 'cf-btn-link', 'close-modal'],
            name: 'Cancel',
            onClick: this.props.onClose
          },
          { classNames: buttonClassNames ? buttonClassNames : ['usa-button', 'confirm'],
            name: this.props.buttonText ? this.props.buttonText : COPY.MODAL_CONFIRM_BUTTON,
            onClick: this.props.onConfirm
          }
        ]}
        visible
        closeHandler={this.props.onClose}
        title={this.props.title}
        icon={this.props.icon}
      >
        {this.props.children}
      </Modal>
    </span>;
  }
}

SaveAlertConfirmModal.propTypes = {
  buttonText: PropTypes.string,
  children: PropTypes.node,
  icon: PropTypes.string,
  onClose: PropTypes.func,
  onConfirm: PropTypes.func,
  title: PropTypes.string,
  buttonClassNames: PropTypes.array
};

export default SaveAlertConfirmModal;
