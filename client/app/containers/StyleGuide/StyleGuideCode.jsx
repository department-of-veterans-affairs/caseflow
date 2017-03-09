export const ModalCode = `
  <Modal
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
`;
