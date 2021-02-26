import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import { useParams } from 'react-router';
import { Link } from 'react-router-dom';


const DocketSwitchAlertBanner = ({ appeal }) => {
  const { appealId } = useParams();
  const docketSwitch = appeal.docketSwitch ? appeal.docketSwitch : appeal.switchedDocket;

  if (docketSwitch.disposition === 'granted') {
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
 } else {
   return (
     <div>
       <Alert
         message={ appeal.docketSwitch ? COPY.DOCKET_SWITCH_PARTIAL_GRANTED_LABEL_NEW_DOCKET : COPY.DOCKET_SWITCH_PARTIAL_GRANTED_LABEL_OLD_DOCKET}
         title={ appeal.docketSwitch ? COPY.DOCKET_SWITCH_PARTIAL_GRANTED_TITLE_NEW_DOCKET : COPY.DOCKET_SWITCH_PARTIAL_GRANTED_TITLE_OLD_DOCKET}
         type="info"
        />
      <br />
     </div>
    );
  };
};

DocketSwitchAlertBanner.propTypes = {
  appeal: PropTypes.object.isRequired
};

export default DocketSwitchAlertBanner;