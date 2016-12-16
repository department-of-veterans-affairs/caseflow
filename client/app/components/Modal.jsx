import React, { PropTypes } from 'react';
import { closeSymbolHtml } from './RenderFunctions.jsx';
import Button from './Button.jsx';

export default class Modal extends React.Component {
  constructor(props) {
    super(props);
    this.buttonIdPrefix = `${this.props.title.replace(/\s/g, '-')}-button-id-`;
  }

  handleTab = (event) => {
    let lastButtonId = this.buttonIdPrefix + (this.props.buttons.length - 1);
    let firstButton = document.getElementById(`${this.props.title}-close-id`);
    let lastButton = document.getElementById(lastButtonId);

    if (event.shiftKey) {
      if (firstButton === document.activeElement) {
        event.preventDefault();
        lastButton.focus();
      }
    } else if (lastButton === document.activeElement) {
      event.preventDefault();
      firstButton.focus();
    }
  }

  keyHandler = (event) => {
    console.log('here' + event);
    if (event.key === "Escape") {
      this.props.closeHandler();
    }

    if (event.key === "Tab") {
      this.handleTab(event);
    }
  }

  componentWillUnmount() {
    window.removeEventListener("keydown", this.keyHandler);
  }

  componentDidMount() {
    window.addEventListener("keydown", this.keyHandler);
  }

  generateButtons() {
    return this.props.buttons.map((object, i) => {
      // If we have more than two buttons, push the
      // first left, and the rest right.
      // If we have just one button, push it right.
      let classNames = ["cf-push-right"];

      if (i === 0 && this.props.buttons.length > 1) {
        classNames = ["cf-push-left"];
      }

      if (typeof object.classNames !== 'undefined') {
        classNames = [...object.classNames, ...classNames];
      }

      return <Button
          name={object.name}
          onClick={object.onClick}
          classNames={classNames}
          loading={object.loading}
          key={i}
          id={this.buttonIdPrefix + i}
        />;
    });
  }

  render() {
    let {
      children,
      closeHandler,
      title
    } = this.props;

    return <section
            className="cf-modal active"
            id="modal_id"
            role="alertdialog"
            aria-labelledby="modal_id-title"
            aria-describedby="modal_id-desc"
          >
      <div className="cf-modal-body">
        <button
          type="button"
          id={`${this.buttonIdPrefix}close`}
          className="cf-modal-close"
          onClick={closeHandler}
        >
          {closeSymbolHtml()}
        </button>
        <h1 className="cf-modal-title" id="modal_id-title">{title}</h1>
        <div className="cf-modal-normal-text">
          {children}
        </div>
        <div className="cf-push-row cf-modal-controls">
          {this.generateButtons()}
        </div>
      </div>
    </section>;
  }
}

Modal.propTypes = {
  butons: PropTypes.arrayOf(PropTypes.object),
  label: PropTypes.string,
  specialContent: PropTypes.func,
  title: PropTypes.string.isRequired
};
