import React from 'react';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import COPY from '../../../COPY';
import { css } from 'glamor';

export const VhaJoinOrgAlert = () => {
  const requestAccessButtonStyling = css({
    marginTop: '30px',
    marginBottom: '30px'
  });

  return (
    <Alert
      title={COPY.VHA_FIRST_LOGIN_INFO_ALERT_TITLE}
      type="info"
      lowerMargin
      key="vhaFlashAlert">
      {COPY.VHA_FIRST_LOGIN_INFO_ALERT_BODY}
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
