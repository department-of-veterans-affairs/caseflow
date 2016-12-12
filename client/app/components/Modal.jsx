import React, { PropTypes } from 'react';
import { closeSymbolHtml } from './RenderFunctions.jsx';
import Button from './Button.jsx';

export default class Modal extends React.Component {
  render() {
    let {
      buttons,
      closeHandler,
      content,
      title,
      visible
    } = this.props;

    return <section className={"cf-modal" + (visible ? " active" : " ")} id="modal_id" role="alertdialog" aria-labelledby="modal_id-title" aria-describedby="modal_id-desc">
      <div className="cf-modal-body">
        <button type="button" className="cf-modal-close" onClick={closeHandler}>
          {closeSymbolHtml()}
        </button>
        <h1 className="cf-modal-title" id="modal_id-title">{title}</h1>
        <p className="cf-modal-text" id="text_id">
          {content}
        </p>
        <div className="cf-push-row cf-modal-controls">
          <table>
            <tbody>
              <tr>
                {buttons.map((object, i) => {
                  let classNames = ["cf-button-array-buttons"];
                  if (object.classNames !== undefined) {
                    classNames = [...object.classNames, ...classNames];
                  }
                  
                  return (<td className="cf-button-array-table-cell" key={i}>
                    <Button
                      name={object.name}
                      onClick={object.onClick}
                      classNames={["cf-button-array-buttons"]}
                      key={i}
                    />
                  </td>)
                })}
              </tr>
            </tbody>
          </table>
          {
          // <button type="button" className="usa-button-outline cf-action-closemodal cf-push-left" data-controls="#<%= modal_id%>">Go back</button>
          // <a href="#" className="cf-push-right usa-button usa-button-secondary">Yes, I'm sure</a>
          }
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
  title: PropTypes.string.isRequired,
  visible: PropTypes.bool.isRequired
};