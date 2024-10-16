import React from 'react';
import _ from 'lodash';
import PropTypes from 'prop-types';


class DocSizeIndicator extends React.Component {
  render() {

    return <span> {this.props.docSize}
    </span>;
  }
}

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired
};

export default DocSizeIndicator;
