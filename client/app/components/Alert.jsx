import React, { PropTypes } from 'react';

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
      message,
      title,
      type
    } = this.props;

    let typeClass = `usa-alert-${type}`;

    return <div className={`cf-app-segment usa-alert ${typeClass}`} {...this.getRole()}>
      <div className="usa-alert-body">
        <h3 className="usa-alert-heading">{title}</h3>
        <p className="usa-alert-text">{message}</p>
      </div>
    </div>;
  }
}

Alert.defaultProps = {
  scrollOnAlert: true
};

Alert.propTypes = {
  message: PropTypes.string.isRequired,
  title: PropTypes.string.isRequired,
  type: PropTypes.oneOf(['success', 'error', 'warning', 'info'])
};

