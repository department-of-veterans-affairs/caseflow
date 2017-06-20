import React from 'react';
import PropTypes from 'prop-types';
import { Link as RouterLink } from 'react-router-dom';

const CLASS_NAME_MAPPING = {
  primary: 'usa-button',
  secondary: 'usa-button-outline',
  disabled: 'usa-button-disabled'
};

export default class Link extends React.Component {
  render() {
    let {
      to,
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

    return <RouterLink
        to={to}
        type={type}
        className={CLASS_NAME_MAPPING[button]}
      >
        {children}
      </RouterLink>;
  }
}

Link.propTypes = {
  to: PropTypes.string,
  button: PropTypes.string,
  children: PropTypes.node
};
