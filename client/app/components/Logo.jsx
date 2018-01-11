import React from 'react';
import PropTypes from 'prop-types';

// TODO I think this class is entirely unused.
export default class Logo extends React.Component {
  render() {
    let app = this.props.app || 'default';

    let logoClass = `cf-logo-image cf-logo-image-${app}`;

    return <span className={logoClass}></span>;
  }
}

Logo.propTypes = {
  app: PropTypes.string
};
