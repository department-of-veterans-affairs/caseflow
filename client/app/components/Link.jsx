import React from 'react';
import PropTypes from 'prop-types';
import { Link as RouterLink } from 'react-router-dom';

const CLASS_NAME_MAPPING = {
  primary: 'usa-button',
  secondary: 'usa-button-outline',
  disabled: 'usa-button-disabled',
  matte: 'link-matte link-overflow'
};

export default class Link extends React.Component {
  render() {
    const {
      ariaLabel,
      to,
      target,
      href,
      button,
      children
    } = this.props;

    const type = button ? 'button' : null;

    if (button === 'disabled') {
      return <p
        type={type}
        className={CLASS_NAME_MAPPING[button]}
      >
        {children}
      </p>;
    }

    const commonProps = {
      'aria-label': ariaLabel,
      target,
      type,
      className: CLASS_NAME_MAPPING[button]
    };

    if (to) {
      return <RouterLink to={to} {...commonProps}>
          {children}
        </RouterLink>;
    } else {
      return <a href={href} {...commonProps}>
          {children}
        </a>;
    }
  }
}

Link.propTypes = {
  href: PropTypes.string,
  to: PropTypes.string,
  button: PropTypes.string,
  children: PropTypes.node
};
