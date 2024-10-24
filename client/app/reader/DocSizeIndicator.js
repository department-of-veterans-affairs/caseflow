import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';

const DocSizeIndicator = (props) => {
  return (
    <span>{filesize(props.docSize)} <SizeWarningIcon size={ICON_SIZES.SMALL} /></span>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired
};

export default DocSizeIndicator;
