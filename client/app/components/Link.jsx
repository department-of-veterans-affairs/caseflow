import React from 'react';
import PropTypes from 'prop-types';
import { Link as ReduxLink} from 'react-router-dom';

export default class Link extends React.Component {
  render() {
    let {
      to,
      className,
      children
    } = this.props;

    return <ReduxLink
        to={to}
        type="button"
        className={className}
      >
        {children}
      </ReduxLink>;
  }
}

Link.propTypes = {
  to: PropTypes.string,
  className: PropTypes.string,
  children: PropTypes.node
};
