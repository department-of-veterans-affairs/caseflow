import React, { PropTypes } from 'react';

export default class SuccessMessage extends React.Component {
  render() {
    let {
      checklist,
      messageList,
      messageText,
      title
    } = this.props;

    return <div id="certifications-generate" className="cf-app-msg-screen cf-app-segment cf-app-segment--alt">
      <h1 className="cf-success cf-msg-screen-heading">{title}</h1>
      {messageList.map((listValue) =>
        <h2 className="cf-msg-screen-deck">
          {listValue}
        </h2>)
      }
      <ul className="cf-list-checklist cf-left-padding">
        {checklist.map((listValue) => <li key={listValue}>
          <span className="cf-icon-success--bg"></span>{listValue}</li>)}
      </ul>
      <p className="cf-msg-screen-text">
        { messageText }
      </p>
    </div>
  }
}

SuccessMessage.props = {
  checklist: PropTypes.array,
  messageList: PropTypes.array,
  messageText: PropTypes.string,
  title: PropTypes.string
};
