import React, { PropTypes } from 'react';
import { closeSymbolHtml } from './RenderFunctions.jsx';
import Button from './Button.jsx';

export default class Modal extends React.Component {

  escapeKeyHandler(event) {
    console.log('here2');
    if (event.key === "Escape"){
      closeHandler();
    }
  }

  componentWillUnmount() {
    window.removeEventListener("keyDown", this.escapeKeyHandler);
  }

  componentDidMount() {
    console.log('here');
    window.addEventListener("keyDown", this.escapeKeyHandler);
  }

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
      <div className="scrollable">
        <button type="button" className="cf-modal-close" onClick={closeHandler}>
          {closeSymbolHtml()}
        </button>
        <h1 className="cf-modal-title" id="modal_id-title">{title}</h1>
        <div className="cf-modal-normal-text">
          {this.props.children}
        </div>
        <div className="cf-push-row cf-modal-controls">
            {buttons.map((object, i) => {
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
                  key={i}
                />;
            })}
        </div>
        </div>
      </div>
    </section>;
  }
}

/*          <table>
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
*/
Modal.propTypes = {
  butons: PropTypes.arrayOf(PropTypes.object),
  content: PropTypes.string,
  specialContent: PropTypes.func,
  label: PropTypes.string,
  title: PropTypes.string.isRequired,
  visible: PropTypes.bool.isRequired
};