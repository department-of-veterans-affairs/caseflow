import React from 'react';

// components
import Modal from '../components/Modal';
import Button from '../components/Button';
import TextareaField from '../components/TextareaField';

export default class StyleGuide extends React.Component {
  constructor(props) {
    super(props);
    window.jqueryOn = false;

    this.state = { modal: false };
  }

  handleModalOpen = () => {
    this.setState({ modal: true });
  };

  handleModalClose = () => {
    this.setState({ modal: false });
  };

  render() {
    let styleGuideModal = this.state.modal;

    return <div>
      <p><Button
          name="Launch Modal"
          onClick={this.handleModalOpen}
          classNames={["usa-button", "usa-button-outline"]}
      /></p>
      { styleGuideModal && <Modal
        buttons = {[
          { classNames: ["cf-modal-link", "cf-btn-link"],
            name: '\u00AB Close',
            onClick: this.handleModalClose
          },
          { classNames: ["usa-button", "usa-button-secondary"],
            name: 'Proceed with Action',
            onClick: this.handleModalClose
          }
        ]}
        closeHandler={this.handleModalClose}
        title = "This is a modal">
        <p>
          This is your modal text, which explains why the modal was triggered.
        </p>
        <TextareaField
          label="This is a text box for the modal."
          name="Text Box"
          onChange={this.handleModalOpen}
        />
      </Modal>
    }
    </div>;
  }
}
