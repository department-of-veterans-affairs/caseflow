import React, { PropTypes } from 'react';

export default class StatusMessage extends React.Component {
  render() {
    let {
      checklist,
      classNames,
      example,
      h1classNames,
      leadMessageList,
      messageText,
      title,
      type
    } = this.props;

    h1classNames = [];

    if (example) {
      classNames.push('cf-sg-success-example');
    }

    let getClassNames = () => {
      if (type === 'success') {
        h1classNames = ['cf-msg-screen-heading', 'cf-success'];
      } else if (type === 'alert') {
        h1classNames = ['cf-msg-screen-heading', 'cf-red-text'];
      } else {
        h1classNames = ['cf-msg-screen-heading'];
      }

      return h1classNames.join(' ');
    };

    return <div id="certifications-generate" className="cf-app-msg-screen cf-app-segment
      cf-app-segment--alt">
      <h1 className={getClassNames()}>{title}</h1>
      {leadMessageList.map((listValue, i) =>
        <h2 className="cf-msg-screen-deck" key={i}>
          {listValue}
        </h2>)
      }

      {type === 'success' && <ul className={classNames.join(' ')}>
        {checklist.map((listValue, i) => <li key={i}>{listValue}</li>)}
      </ul>}
      <p className="cf-msg-screen-text">
        { messageText }
      </p>
    </div>;
  }
}

StatusMessage.defaultProps = {
  classNames: ['cf-success-checklist', 'cf-left-padding']
};

StatusMessage.props = {
  checklist: PropTypes.array,
  leadMessageList: PropTypes.array,
  messageText: PropTypes.string,
  title: PropTypes.string,
  type: PropTypes.string
};
