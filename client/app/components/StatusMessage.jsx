import React from 'react';
import PropTypes from 'prop-types';
import { map } from 'lodash';
import classNamesFn from 'classnames';

export const StatusMessage = (props) => {
  const {
    checklist,
    checklistClassNames,
    leadMessageList,
    messageText,
    title,
    wrapInAppSegment,
    children,
    type
  } = props;

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

  const wrapperClassName = classNamesFn({
    'cf-app-segment cf-app-segment--alt': wrapInAppSegment
  });

  return <div id="certifications-generate" className={wrapperClassName}>
    <h1 className={getClassNames()}>{title}</h1>

    { children ?
      <h2 className="cf-msg-screen-deck">
        {children}
      </h2> :
      map(leadMessageList, (listValue, i) =>
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
};

StatusMessage.defaultProps = {
  checklistClassNames: ['cf-success-checklist', 'cf-left-padding'],
  wrapInAppSegment: true,
  type: 'status'
};

StatusMessage.propTypes = {

  /**
   * List of actions to show as complete in a checklist. Only for `type` "success"
   */
  checklist: PropTypes.array,

  /**
   * Class or classes to apply to the checklist `ul` element
   */
  checklistClassNames: PropTypes.oneOfType([PropTypes.string, PropTypes.array]),

  /**
   * Child nodes to show in the message. `leadMessageList` will be used if not defined.
   */
  children: PropTypes.node,

  /**
   * Array of messages to display in the component. Will not be used if `children` is defined or this component wraps
   * another
   */
  leadMessageList: PropTypes.array,

  /**
   * Text to display beneath the provided `children` (or `leadMessageList`) and checklist.
   */
  messageText: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.node
  ]),

  /**
   * The heading of the message
   */
  title: PropTypes.string,

  /**
   * The type of message to show. Determines the styling of the heading.
   */
  type: PropTypes.oneOf(['alert', 'status', 'success', 'warning']),
  wrapInAppSegment: PropTypes.bool
};

export default StatusMessage;
