import React from 'react';

// components
import Modal from '../../components/Modal';
import Button from '../../components/Button';
import TextareaField from '../../components/TextareaField';
import StyleGuideComponentTitle from '../../components/StyleGuideComponentTitle';

export default class StyleGuideModal extends React.PureComponent {
  constructor(props) {
    super(props);
    window.jqueryOn = false;

    this.state = {
      modal: false,
      iconModal: false,
      value: ''
    };
  }

  handleModalOpen = () => {
    this.setState({ modal: true });
  };

  handleModalClose = () => {
    this.setState({ modal: false });
  };

  handleIconModalOpen = () => {
    this.setState({ iconModal: true });
  };

  handleIconModalClose = () => {
    this.setState({ iconModal: false });
  };

  render() {
    let styleGuideModal = this.state.modal;
    let styleGuideIconModal = this.state.iconModal;

    return <div>
      <StyleGuideComponentTitle
        title="Modals"
        id="modals"
        link="StyleGuideModal.jsx"
      />
      <p>Modals are 490 pixels in width with 30px padding around the border and
        contain the following: a title, explanation text, a divider,
        and action buttons. There are modal-specific classes that must be included
        in your modal (see below code snippets).
        Whenever possible, use a close link as the left action.</p>
      <div className="usa-grid">
        <div class="usa-width-one-half">
          <Button
            name="Launch modal"
            onClick={this.handleModalOpen}
            classNames={['usa-button', 'usa-button-secondary']} />
        </div>
        <div class="usa-width-one-half">
          <Button
            name="Launch icon modal"
            onClick={this.handleIconModalOpen}
            classNames={['usa-button', 'usa-button-secondary']} />
        </div>
      </div>
      { styleGuideModal && <Modal
        buttons = {[
          { classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Close',
            onClick: this.handleModalClose
          },
          { classNames: ['usa-button', 'usa-button-secondary'],
            name: 'Proceed with action',
            onClick: this.handleModalClose
          }
        ]}
        closeHandler={this.handleModalClose}
        title = "This is a Modal">
        <p>
          This is your modal text, which explains why the modal was triggered.
          Modal titles are in <b>Title Case</b>, but actions on modal features
          such as text explanations, action buttons, fields, etc. are
          <b> Sentence case</b>.
        </p>
        <TextareaField
          label="This is a text box for the modal."
          name="Text Box"
          onChange={(value) => {
            this.setState({ value });
          }}
          value={this.state.value}
        />
      </Modal>
      }
      { styleGuideIconModal && <Modal
        buttons = {[
          { classNames: ['cf-modal-link', 'cf-btn-link'],
            name: 'Close',
            onClick: this.handleIconModalClose
          },
          { classNames: ['usa-button', 'usa-button-secondary'],
            name: 'Proceed with action',
            onClick: this.handleIconModalClose
          }
        ]}
        closeHandler={this.handleIconModalClose}
        title = "This is a Modal with an icon"
        icon="warning">
        <p>
          This is a modal with an icon. Icons are optional on modals and are set by the designer in the mockup.
          These icons come from the Font Awesome package, which is set in the U.S. Design standards.
        </p>
      </Modal>
      }
    </div>;
  }
}
