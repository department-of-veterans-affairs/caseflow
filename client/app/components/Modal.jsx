import React, { PropTypes } from 'react';
import { closeSymbolHtml } from './RenderFunctions.jsx';
import Button from './Button.jsx';

export default class Modal extends React.Component {

  escapeKeyHandler = (event) => {
    if (event.key === "Escape"){
      this.props.closeHandler();
    }
  }

  componentWillUnmount() {
    window.removeEventListener("keydown", this.escapeKeyHandler);
  }

  componentDidMount() {
    window.addEventListener("keydown", this.escapeKeyHandler);
  }

  render() {
    let {
      buttons,
      closeHandler,
      content,
      title
    } = this.props;

    return <section className="cf-modal active" id="modal_id" role="alertdialog" aria-labelledby="modal_id-title" aria-describedby="modal_id-desc">
      <div className="cf-modal-body">
        <button type="button" className="cf-modal-close" onClick={closeHandler}>
          {closeSymbolHtml()}
        </button>
        <h1 className="cf-modal-title" id="modal_id-title">{title}</h1>
        <div className="cf-modal-normal-text">
          {this.props.children}
        </div>
        <div className="cf-push-row cf-modal-controls">
            {buttons.map((object, i) => {
              {
                // If we have more than two buttons, push the first left, and the rest right.
                // If we have just one button, push it right.
              }
              let classNames = ["cf-push-right"];
              if (i == 0 && buttons.length > 1) {
                classNames = ["cf-push-left"];
              }
              
              if (object.classNames !== undefined) {
                classNames = [...object.classNames, ...classNames];
              }
              
              return <Button
                  name={object.name}
                  onClick={object.onClick}
                  classNames={classNames}
                  loading={object.loading}
                  key={i}
                />;
            })}
        </div>
      </div>
    </section>;
  }
}

Modal.propTypes = {
  butons: PropTypes.arrayOf(PropTypes.object),
  content: PropTypes.string,
  specialContent: PropTypes.func,
  label: PropTypes.string,
  title: PropTypes.string.isRequired
};