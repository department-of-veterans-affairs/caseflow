import PropTypes from 'prop-types';
import React from 'react';
import { rowThirds } from './style';
import StringUtil from 'app/util/StringUtil';

const labelStyles = {
  fontWeight: 'bold'
};

const pStyles = {
  marginTop: '2rem'
};

const TranscriberDetails = ({ hearing }) => {
  const getSafeValue = (value) => value || 'N/A';

  return (
    <div>
      <div {...rowThirds}>
        <div>
          <label style={labelStyles}>Recorder</label>
          <p style={pStyles}>
            {StringUtil.capitalizeFirst(getSafeValue(hearing?.conferenceProvider))}
          </p>
        </div>
        <div>
          <label style={labelStyles}>Recording date</label>
          <p style={pStyles}>
            {getSafeValue(hearing?.scheduledTime)}
          </p>
        </div>
        <div>
          <label style={labelStyles}>Retrieval date</label>
          <p style={pStyles}>
            {getSafeValue(hearing?.dateReceiptRecording)}
          </p>
        </div>
      </div>
    </div>
  );
};

TranscriberDetails.propTypes = {
  hearing: PropTypes.shape({
    determineServiceName: PropTypes.string,
    scheduledTime: PropTypes.string,
    dateReceiptRecording: PropTypes.string,
  }),
};

export default TranscriberDetails;
