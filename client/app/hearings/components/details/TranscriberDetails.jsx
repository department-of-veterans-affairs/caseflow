import PropTypes from 'prop-types';
import React from 'react';
import { rowThirds } from './style';
import { css } from 'glamor';
import StringUtil from 'app/util/StringUtil';

const detailStyles = css({
  '& label': {
    fontWeight: 'bold',
  },
  '& p': {
    marginTop: '2rem',
  },
});

const TranscriberDetails = ({ hearing }) => {
  const getSafeValue = (value) => value || 'N/A';

  return (
    <div {...detailStyles}>
      <div {...rowThirds}>
        <div>
          <label>Recorder</label>
          <p>
            {StringUtil.capitalizeFirst(getSafeValue(hearing?.determineServiceName))}
          </p>
        </div>
        <div>
          <label>Recording date</label>
          <p>
            {getSafeValue(hearing?.scheduledTime)}
          </p>
        </div>
        <div>
          <label>Retrieval date</label>
          <p>
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
