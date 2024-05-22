import React from "react";

class HelloWorldModal extends React.Component {
  render() {
    const { show, handleClose } = this.props;

    const modalStyle = {
      display: show ? "block" : "none",
      position: "fixed",
      zIndex: 1,
      left: 0,
      top: 0,
      width: "100%",
      height: "100%",
      overflow: "auto",
      backgroundColor: "rgba(0,0,0,0.4)",
    };

    const modalContentStyle = {
      backgroundColor: "#fefefe",
      margin: "15% auto",
      padding: "20px",
      border: "1px solid #888",
      width: "80%",
    };

    return (
      <div style={modalStyle}>
        <div style={modalContentStyle}>
          HelloWorld
          <button onClick={handleClose}>Close</button>
        </div>
      </div>
    );
  }
}

export default HelloWorldModal;
