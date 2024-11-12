import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';
import { documentDownloadTime } from './utils/network';

const DocSizeIndicator = (props) => {
  const downloadTime = documentDownloadTime(props.docSize, props.browserSpeedInBytes);

  return (
    <div data-warning-threshold={props.warningThreshold} style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {filesize(props.docSize, { round: 1 })}&nbsp;
      {downloadTime > props.warningThreshold ? <SizeWarningIcon size={ICON_SIZES.SMALL} /> : ''}
    </div>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired,
  browserSpeedInBytes: PropTypes.number.isRequired,
  warningThreshold: PropTypes.number.isRequired
};

export default DocSizeIndicator;
