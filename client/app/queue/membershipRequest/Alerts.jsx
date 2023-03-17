import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import COPY from '../../../COPY';
import { css } from 'glamor';

export const VhaJoinOrgAlert = () => {

  const VHAOrgJoinInfoObject = {
    title: COPY.VHA_FIRST_LOGIN_INFO_ALERT_TITLE,
    text: COPY.VHA_FIRST_LOGIN_INFO_ALERT_BODY
  };

  const requestAccessButtonStyling = css({
    marginTop: '30px',
    marginBottom: '30px'
  });

  return (
    <Alert
      title={VHAOrgJoinInfoObject.title}
      type="info"
      lowerMargin>
      {VHAOrgJoinInfoObject.text}
      <div className={requestAccessButtonStyling}>
        <Button onClick={() => {
          window.location.href = '/vha/help';
        }}
        dangerStyling>
          Request access
        </Button>
      </div>
    </Alert>
  );
};

VhaJoinOrgAlert.propTypes = {
  VHAOrgJoinInfoCode: PropTypes.string,
};
