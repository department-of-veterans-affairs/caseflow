import PropTypes from 'prop-types';
import React from 'react';
import { rowThirds } from './style';
import { css } from 'glamor';

const detailStyles = css({
  '& label': {
    fontWeight: 'bold',
  },
  '& p': {
    marginTop: '2rem'
  }
});

const TranscriberDetails = ({ hearing }) => {
  return (
    <div {...detailStyles}>
      <div {...rowThirds}>
        <div>
          <label>Recorder</label>
          <p>{hearing?.determineServiceName || 'N/A'}</p>
        </div>
        <div>
          <label>Recording Date</label>
          <p>{hearing?.scheduledTime || 'N/A'}</p>
        </div>
        <div>
          <label>Retrieval Date</label>
          <p>{hearing?.dateReceiptRecording || 'N/A'}</p>
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

