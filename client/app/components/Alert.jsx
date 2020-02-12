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

  getRole() {
    let attrs = {};

    if (this.props.type === 'error') {
      attrs.role = 'alert';
    }

    return attrs;
  }

  messageDiv() {
    let message = this.props.children || this.props.message;

    return <div className="usa-alert-text">{message}</div>;
  }

  render() {
    let {
      fixed,
      title,
      type,
      styling,
      lowerMargin
    } = this.props;

    let typeClass = `usa-alert-${type}`;

    const className = classnames('usa-alert', typeClass, {
      'usa-alert-slim': !title,
      fixed,
      'cf-margin-bottom-2rem': lowerMargin
    });

    return <div className={className} {...this.getRole()} {...styling}>
      <div className="usa-alert-body">
        <h2 className="usa-alert-heading">{title}</h2>
        { this.messageDiv() }
      </div>
    </div>;
  }
}

Alert.defaultProps = {
  scrollOnAlert: true
};

Alert.propTypes = {
  children: PropTypes.node,
  fixed: PropTypes.string,
  lowerMargin: PropTypes.bool,
  message: PropTypes.node,
  title: PropTypes.string,
  type: PropTypes.oneOf(['success', 'error', 'warning', 'info']).isRequired,
  styling: PropTypes.oneOfType([
    PropTypes.string,
    PropTypes.object
  ]),
  scrollOnAlert: PropTypes.bool
};
