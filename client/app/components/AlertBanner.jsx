import React from 'react';
import PropTypes from 'prop-types';

import classnames from 'classnames';

export default class AlertBanner extends React.PureComponent {
  render() {
    const {
      children,
      title,
      type
    } = this.props;

    const classes = classnames('usa-alert cf-app-segment', {
      'usa-alert-info': type === 'info',
      'usa-alert-error': type === 'error',
      'usa-alert-warning': type === 'warning',
      'usa-alert-success': type === 'success'
    });

    return <div className={classes} role="alert">
        <div className="usa-alert-body">
          <h2 className="usa-alert-heading">{title}</h2>
          <p className="usa-alert-text">{children}</p>
        </div>
    </div>;
  }
}

AlertBanner.props = {
  children: PropTypes.node,
  title: PropTypes.string,
  type: PropTypes.string.isRequired
};
