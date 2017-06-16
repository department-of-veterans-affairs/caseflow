import React from 'react';
import PropTypes from 'prop-types';
import { Link as ReduxLink} from 'react-router-dom';

export default class Link extends React.Component {
  className = (button) => {
    switch(button) {
      case 'primary':
        return 'usa-button';
      case 'secondary':
        return 'usa-button-outline';
      case 'disabled':
        return 'usa-button-disabled';
    }
  }

  render() {
    let {
      to,
      button,
      children
    } = this.props;

    const type = button ? "button" : null;
    const className = this.className(button);

    if (button === 'disabled') {
      return <p
        type={type}
        className={className}
      >
        {children}
      </p>;
    } else {
      return <ReduxLink
        to={to}
        type={type}
        className={className}
      >
        {children}
      </ReduxLink>;
    }
  }
}

Link.propTypes = {
  to: PropTypes.string,
  button: PropTypes.bool,
  children: PropTypes.node
};
