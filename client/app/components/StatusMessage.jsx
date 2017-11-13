import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import classNamesFn from 'classnames';

export default class StatusMessage extends React.Component {
  render() {
    let {
      checklist,
      checklistClassNames,
      example,
      // leadMessageList: 20px font for page text: used for primary message text
      leadMessageList,
      // messageText: 17px font for page text: used for secondary message text
      // underneath leadMessageList
      messageText,
      title,
      wrapInAppSegment = true,
      children,
      type
    } = this.props;

    if (example) {
      checklistClassNames.push('cf-sg-success-example');
    }

    let getClassNames = () => {
      let h1classNames = ['cf-msg-screen-heading'];

      if (type === 'success') {
        h1classNames.push('cf-success');
      } else if (type === 'alert') {
        h1classNames.push('cf-red-text');
      } else if (type === 'warning') {
        h1classNames.push('usa-alert-error', 'cf-warning');
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
      {type === 'success' && checklist && <ul className={checklistClassNames.join(' ')}>
        {checklist.map((listValue, i) => <li key={i}>{listValue}</li>)}
      </ul>}
      <p className="cf-msg-screen-text">
        { messageText }
      </p>
    </div>;
  }
}

StatusMessage.defaultProps = {
  checklistClassNames: ['cf-success-checklist', 'cf-left-padding']
};

StatusMessage.props = {
  checklist: PropTypes.array,
  leadMessageList: PropTypes.array,
  messageText: PropTypes.string,
  title: PropTypes.string,
  type: PropTypes.string
};
