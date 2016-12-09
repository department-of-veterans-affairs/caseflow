import React, { PropTypes } from 'react';
export default class Modal extends React.Component {
  render() {
    { label, title, content } = this.state;
    return <section className="cf-modal active" id="modal_id" role="alertdialog" aria-labelledby="modal_id-title" aria-describedby="modal_id-desc">
      <div className="cf-modal-body">
        <button type="button" className="cf-modal-close cf-action-closemodal">
          Test
        </button>
        <h1 className="cf-modal-title" id="modal_id-title">{title}</h1>
        <p className="cf-modal-text" id="text_id">
          {content}
        </p>

        <div className="cf-push-row cf-modal-controls">
          <button type="button" className="usa-button-outline cf-action-closemodal cf-push-left" data-controls="#<%= modal_id%>">Go back</button>
          <a href="#" className="cf-push-right usa-button usa-button-secondary">Yes, I'm sure</a>
        </div>
      </div>
    </section>;
  }
}

Checkbox.propTypes = {
  label: PropTypes.string,
  title: PropTypes.string.isRequired,
  content: PropTypes.string
};