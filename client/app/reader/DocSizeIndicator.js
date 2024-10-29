import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';

const DocSizeIndicator = (props) => {
  const downloadTime = props.docSize / props.browserSpeedInBytes;

  return (
    <span>{filesize(props.docSize, { round: 1 })} {downloadTime > 15 ? <SizeWarningIcon size={ICON_SIZES.SMALL} /> : ''}</span>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired,
  browserSpeedInBytes: PropTypes.number.isRequired
};

export default DocSizeIndicator;
