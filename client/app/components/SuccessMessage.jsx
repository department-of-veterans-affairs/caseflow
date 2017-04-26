import React, { PropTypes } from 'react';

export default class SuccessMessage extends React.Component {
  render() {
    let {
      checklist,
      leadMessageList,
      messageText,
      title
    } = this.props;

    return <div id="certifications-generate" className="cf-app-msg-screen cf-app-segment
      cf-app-segment--alt">
      <h1 className="cf-success cf-msg-screen-heading">{title}</h1>
      {leadMessageList.map((listValue) =>
        <h2 className="cf-msg-screen-deck" key={listValue}>
          {listValue}
        </h2>)
      }
      <ul className="cf-success-checklist cf-left-padding">
        {checklist.map((listValue) => <li key={listValue}>{listValue}</li>)}
      </ul>
      <p className="cf-msg-screen-text">
        { messageText }
      </p>
    </div>;
  }
}

SuccessMessage.props = {
  checklist: PropTypes.array,
  leadMessageList: PropTypes.array,
  messageText: PropTypes.string,
  title: PropTypes.string
};
