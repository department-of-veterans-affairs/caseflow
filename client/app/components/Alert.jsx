import React from 'react';
import PropTypes from 'prop-types';

import classnames from 'classnames';

export default class Alert extends React.Component {
  componentDidMount() {
    // Scroll to top so alert is visible
    if (this.props.scrollOnAlert) {
      window.scrollTo(0, 0);
    }
  }

  // determine if role should be added to main wrapper div
  // in order to be 508 accessible
  getRole() {
    let attrs = {};

    if (this.props.type === 'error') {
      attrs.role = 'alert';
    }

    return attrs;
  }

  render() {
    let {
      lowerMargin,
      children,
      message,
      title,
      type
    } = this.props;

    let typeClass = `usa-alert-${type}`;

    const className = classnames('usa-alert', typeClass, {
      'lower-margin': lowerMargin,
      'no-title': !title
    });

    return <div className={className} {...this.getRole()}>
      <div className="usa-alert-body">
        <h2 className="usa-alert-heading">{title}</h2>
        { children ? <div className="usa-alert-text">{children}</div> :
          <div className="usa-alert-text">{message}</div>}
      </div>
    </div>;
  }
}

Alert.defaultProps = {
  scrollOnAlert: true
};

Alert.propTypes = {
  children: PropTypes.node,
  message: PropTypes.node,
  title: PropTypes.string,
  type: PropTypes.oneOf(['success', 'error', 'warning', 'info']).isRequired
};
