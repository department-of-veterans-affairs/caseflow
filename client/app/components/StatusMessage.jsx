import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import classNamesFn from 'classnames';

export default class StatusMessage extends React.Component {
  render() {
    let {
      checklist,
      // TODO(nth) This is not a good variable name. It shadows the classNames node module.
      // And it's too generic – the classNames are applied to one specific child element, but
      // you'd never know what that element is by looking at the variable name.
      classNames,
      example,
      h1classNames,
      leadMessageList,
      messageText,
      title,
      wrapInAppSegment = true,
      children,
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

    const wrapperClassName = classNamesFn('cf-app-msg-screen', {
      'cf-app-segment cf-app-segment--alt': wrapInAppSegment
    });

    return <div id="certifications-generate" className={wrapperClassName}>
      <h1 className={getClassNames()}>{title}</h1>

      { children ?
        <h2 className="cf-msg-screen-deck">
          {children}
        </h2> :
        _.map(leadMessageList, (listValue, i) =>
          <h2 className="cf-msg-screen-deck" key={i}>
            {listValue}
          </h2>)
      }
      {type === 'success' && checklist && <ul className={classNames.join(' ')}>
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
