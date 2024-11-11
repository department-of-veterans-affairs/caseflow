import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';


const DocSizeIndicator = (props) => {
  const downloadTime = props.docSize / props.browserSpeedInBytes

  return (
    <span>{filesize(props.docSize)} {downloadTime > 15 ? <SizeWarningIcon size={ICON_SIZES.SMALL} /> : ''}</span>
  );
};

const LARGE_FILE_SIZE_THRESHOLD = 30 * 1024 * 1024; // 30 MB in bytes

const DocSizeIndicator = ({n filesize }) => {
  const isLargeFile = fileSize > LARGE_FILE_SIZE_THRESHOLD;

  return (
    <div className="doc-size-indicator">
      {isLargeFile && <SizeWarningIcon size={24} className="large-file-warning" />}
    </div>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired,
  browserSpeedInBytes: PropTypes.number.isRequired
};

export default DocSizeIndicator;
