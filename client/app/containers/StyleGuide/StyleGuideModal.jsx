import React from 'react';

// components
import Modal from '../../components/Modal';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
// import { ModalCode } from './StyleGuideCode'; //will be used for code samples

export default class StyleGuideModal extends React.Component {
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
      <h2 id="modals">Modals</h2>
        <p>Modals are 490 pixels in width with 30px padding around the border and
        contain the following: a title, explanation text, a divider,
        and action buttons. There are modal-specific classes that must be included
        in your modal (see below code snippets).
        Whenever possible, use a close link as the left action.</p>
      <p><Button
          name="Launch Modal"
          onClick={this.handleModalOpen}
          classNames={["usa-button", "usa-button-outline"]}
      /></p>
      { styleGuideModal && <Modal
        buttons = {[
          { classNames: ["cf-modal-link", "cf-btn-link"],
            name: 'Close',
            onClick: this.handleModalClose
          },
          { classNames: ["usa-button", "usa-button-secondary"],
            name: 'Proceed with action',
            onClick: this.handleModalClose
          }
        ]}
        closeHandler={this.handleModalClose}
        title = "This is a modal">
        <p>
          This is your modal text, which explains why the modal was triggered.
          Modal titles are in <b>Title Case</b>, but actions on modal features
          such as text explanations, action buttons, fields, etc. are
          <b> Sentence case</b>.
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
