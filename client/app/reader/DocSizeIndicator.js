import React, { useState } from 'react';
import PropTypes from 'prop-types';
import { filesize } from 'filesize';
import { SizeWarningIcon } from '../components/icons/SizeWarningIcon';
import { ICON_SIZES } from '../constants/AppConstants';
import { documentDownloadTime } from './utils/network';

const DocSizeIndicator = (props) => {
  const [showMessage, setShowMessage] = useState(false);

  const downloadTime = documentDownloadTime(props.docSize, props.browserSpeedInBytes);
  const waitTime = parseInt(props.warningThreshold, 10) || 15;

  const showIcon = () => {
    if (props.featureToggles.warningIconAndBanner && downloadTime > waitTime) {
      props.enableBandwidthBanner();
      return true;
    }
    return false;
  };

  const handleMouseEnter = () => setShowMessage(true);
  const handleMouseLeave = () => setShowMessage(false);

  return (
    <div
      data-warning-threshold={waitTime}
      data-bandwidth={filesize(props.browserSpeedInBytes)}
      style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}
    >
      <div
        style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative' }}
      >
        {filesize(props.docSize, { round: 1 })}&nbsp;
        {showIcon() && (
          <div
            style={{ position: 'relative', display: 'inline-block' }}
            onMouseEnter={handleMouseEnter}
            onMouseLeave={handleMouseLeave}
          >
            <SizeWarningIcon size={ICON_SIZES.SMALL} />
            {showMessage && (
              <div
                style={{
                  color: 'white',
                  backgroundColor: 'black',
                  padding: '5px',
                  marginTop: '5px',
                  fontSize: '0.9rem',
                  borderRadius: '3px',
                  position: 'absolute',
                  zIndex: 1,
                  top: '100%',
                  left: '50%',
                  transform: 'translateX(-50%)',
                  whiteSpace: 'nowrap',
                }}
              >
                This document may be slow to load
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

DocSizeIndicator.propTypes = {
  docSize: PropTypes.number.isRequired,
  browserSpeedInBytes: PropTypes.number.isRequired,
  warningThreshold: PropTypes.number.isRequired,
  enableBandwidthBanner: PropTypes.func.isRequired,
  featureToggles: PropTypes.shape({
    warningIconAndBanner: PropTypes.bool.isRequired,
  }).isRequired,
};

export default DocSizeIndicator;
