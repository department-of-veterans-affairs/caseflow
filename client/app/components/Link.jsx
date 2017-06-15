import React from 'react';
import PropTypes from 'prop-types';
import { Link as ReduxLink} from 'react-router-dom';

export default class Link extends React.Component {
  render() {
    let {
      to,
      children
    } = this.props;

    return <ReduxLink
        to={to}
        type="button"
        className="usa-button-outline"
      >
        {children}
      </ReduxLink>;
  }
}

Link.propTypes = {
  to: PropTypes.string
};
