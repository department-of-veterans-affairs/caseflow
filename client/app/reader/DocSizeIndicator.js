import React from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';
import { documentDownloadTime } from './utils/network';

const DocSizeIndicator = (props) => {
  const downloadTime = documentDownloadTime(props.docSize, props.browserSpeedInBytes);
  const waitTime = parseInt(props.warningThreshold, 10) || 15;

  const showIcon = () => {
    if (downloadTime > waitTime) {
      props.enableBandwidthBanner();

      return true;
    }
  };

  return (
    <div data-warning-threshold={waitTime}
      data-bandwidth={filesize(props.browserSpeedInBytes)}
      style={{ display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
      {filesize(props.docSize, { round: 1 })}&nbsp;
      {showIcon() ? <SizeWarningIcon size={ICON_SIZES.SMALL} /> : ''}
    </div>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired,
  browserSpeedInBytes: PropTypes.number.isRequired,
  warningThreshold: PropTypes.number.isRequired,
  showBandwidthWarning: PropTypes.func.isRequired,
  enableBandwidthBanner: PropTypes.func.isRequired
};

export default DocSizeIndicator;
