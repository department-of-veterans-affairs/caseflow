/* eslint-disable react/prop-types */
import React from 'react';
import PropTypes from 'prop-types';
import ScrollLock from 'react-scrolllock';
import { closeSymbolHtml } from './RenderFunctions';
import Button from './Button';
import _ from 'lodash';
import { css } from 'glamor';

const modalTextStyling = css({ width: '100%', fontFamily: 'Source Sans Pro' });

/**
 * Method to determine whether the body is wrapped in an outer component
 * @param {Object} props -- An optional wrapper component for the Modal and DOM children
 */
export const BodyWrapper = ({ Wrapper, children }) => (Wrapper ? <Wrapper>{children}</Wrapper> : children);

/**
 * Method to Determine whether to show the Modal
 * @param {Object} props -- Whether the modal should be shown  and DOM children
 */
export const ModalWrapper = ({ show, children, ...props }) =>
  show === undefined ?
    children :
    show && (
      <BodyWrapper show={show} {...props}>
        {children}
      </BodyWrapper>
    );

export default class Modal extends React.Component {
  constructor(props) {
    super(props);
    this.buttonIdPrefix = `${this.props.title.replace(/\s/g, '-')}-button-id-`;
  }
  handleTab = (event) => {
    let buttonsList = document.querySelectorAll('.cf-modal-controls button');
    let firstButton = document.getElementById(`${this.buttonIdPrefix}close`);
    // a more general selector for the last button in the modall
    let endButton = buttonsList[buttonsList.length - 1];

    if (event.shiftKey) {
      if (firstButton === document.activeElement) {
        event.preventDefault();
        endButton.focus();
      }
    } else if (endButton === document.activeElement) {
      event.preventDefault();
      firstButton.focus();
    }
  };

  keyHandler = (event) => {
    if (event.key === 'Escape') {
      this.props.closeHandler();
    }

    if (event.key === 'Tab') {
      this.handleTab(event);
    }
  };

  modalCloseFocus = (modalClose) => (this.modalClose = modalClose);

  componentWillUnmount() {
    window.removeEventListener('keydown', this.keyHandler);
    // return focus to original target
    // document.querySelector('.cf-btn-link').focus();
  }

  componentDidMount() {
    window.addEventListener('keydown', this.keyHandler);
    this.modalClose.focus();
  }

  generateButtons() {
    return this.props.buttons.map((object, i) => {
      // If we have more than two buttons, push the
      // first left, and the rest right.
      // If we have just one button, push it right.
      let classNames = ['cf-push-right'];

      if (i === 0 && this.props.buttons.length > 1) {
        classNames = ['cf-push-left'];
      }

      if (typeof object.classNames !== 'undefined') {
        classNames = [...object.classNames, ...classNames];
      }

      return (
        <Button
          name={object.name}
          onClick={object.onClick}
          classNames={classNames}
          loading={object.loading}
          disabled={object.disabled}
          key={i}
          id={this.buttonIdPrefix + i}
        />
      );
    });
  }

  render() {
    const {
      children,
      className,
      closeHandler,
      id,
      noDivider,
      confirmButton,
      cancelButton,
      title,
      customStyles,
      show,
      Wrapper
    } = this.props;

    let modalButtons;

    if (!confirmButton && !cancelButton) {
      modalButtons = this.generateButtons();
    } else {
      modalButtons = (
        <div>
          <span className="cf-push-right">{confirmButton}</span>
          {cancelButton && <span className="cf-push-left">{cancelButton}</span>}
        </div>
      );
    }

    return (
      <ModalWrapper show={show} Wrapper={Wrapper}>
        <section
          className={`cf-modal active ${className}`}
          id="modal_id"
          role="alertdialog"
          aria-labelledby="modal_id-title"
          aria-describedby="modal_id-desc"
          aria-modal="true"
        >
          <ScrollLock />
          <div className="cf-modal-body" id={id || ''} {...customStyles}>
            <button
              type="button"
              id={`${this.buttonIdPrefix}close`}
              className="cf-modal-close"
              onClick={closeHandler}
              ref={this.modalCloseFocus}
            >
              {closeSymbolHtml()}
            </button>
            <h1 id="modal_id-title">{title}</h1>
            <div {...modalTextStyling}>{children}</div>
            {noDivider ? '' : <div className="cf-modal-divider" />}
            <div className="cf-modal-controls">{modalButtons}</div>
          </div>
        </section>
      </ModalWrapper>
    );
  }
}

Modal.defaultProps = {
  buttons: []
};

Modal.propTypes = {
  buttons: (props, propName) => {
    const buttons = props[propName];

    if (!_.isArray(buttons)) {
      return new Error(`'buttons' must be an array, but was: '${buttons}'`);
    }

    if (buttons.length && (props.cancelButton || props.confirmButton)) {
      return new Error('You cannot set both `buttons` and one of `confirmButton` or `cancelButton`');
    }
  },
  className: PropTypes.string,
  confirmButton: PropTypes.element,
  cancelButton: PropTypes.element,
  id: PropTypes.string,
  label: PropTypes.string,
  noDivider: PropTypes.bool,
  specialContent: PropTypes.func,
  title: PropTypes.string.isRequired,
  show: PropTypes.bool,
  Wrapper: PropTypes.element
};

Modal.defaultProps = {
  className: ''
};
