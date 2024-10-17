import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';

const DocSizeIndicator = (props) => {
  return (
    <span>{filesize(props.docSize)}</span>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired
};

export default DocSizeIndicator;
