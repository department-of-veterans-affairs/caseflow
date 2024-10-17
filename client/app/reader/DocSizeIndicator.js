import React from 'react';
import PropTypes from 'prop-types';

const DocSizeIndicator = (props) => {
  return (
    <span>{props.docSize}</span>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired
};

export default DocSizeIndicator;
