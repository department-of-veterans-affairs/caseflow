import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import { useParams } from 'react-router';
import { Link } from 'react-router-dom';


const DocketSwitchBanner = ({ appeal }) => {
  const { appealId } = useParams();

  return (
    <div>
      <Alert
        message={COPY.DOCKET_SWITCH_FULL_GRANTED_LABEL}
        title={COPY.DOCKET_SWITCH_FULL_GRANTED_TITLE}
        type="info"
      />
      <br />
    </div>
  );
};

DocketSwitchBanner.propTypes = {
  appeal: PropTypes.object.isRequired
};

export default DocketSwitchBanner;