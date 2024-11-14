import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';

const MAX_FILE_WAIT_TIME = 30 * 1024 * 1024; // 30 MB in bytes

const DocSizeIndicator = ({ docSize, browserSpeedInBytes }) => {
  const downloadTime = docSize / browserSpeedInBytes;
  const isLargeFile = docSize > MAX_FILE_WAIT_TIME;

  return (
    <span>
      {filesize(docSize)}
      {downloadTime > 15 && isLargeFile && (
        <SizeWarningIcon size={ICON_SIZES.SMALL} />
      )}
    </span>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired,
  browserSpeedInBytes: PropTypes.number.isRequired
};

export default DocSizeIndicator;
