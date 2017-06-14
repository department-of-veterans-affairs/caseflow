import React from 'react';
import PropTypes from 'prop-types';
import { Link } from 'react-router-dom';

export default class Link extends React.Component {
  typeOfLink = () => {
    if (this.props.to) {
      return Link;
    } else if (this.props.href) {
      return a;
    }
  }

  render() {
    let {
      to,
      href,
      children
    } = this.props;

    const typeOfLink = this.typeOfLink();

    return <typeOfLink
        to={to}
        href={href}
      >
        {children}
      </Link>;

    } else if (href) {
      return <a >{children}</a>;
    }
  }
}

Button.defaultProps = {
  classNames: ['cf-submit'],
  type: 'button'
};

Button.propTypes = {
  ariaLabel: PropTypes.string,
  children: PropTypes.node,
  classNames: PropTypes.arrayOf(PropTypes.string),
  disabled: PropTypes.bool,
  id: PropTypes.string,
  linkStyle: PropTypes.bool,
  loading: PropTypes.bool,
  name: PropTypes.string.isRequired,
  onClick: PropTypes.func,
  type: PropTypes.string
};
