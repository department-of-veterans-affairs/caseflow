import React from 'react';
import PropTypes from 'prop-types';
import Button from '../../components/Button';
import Alert from '../../components/Alert';
import { css } from 'glamor';

export const VHAOrgJoinInfo = () => {

  const VHAOrgJoinInfoObject = {
    title: 'VHA Team Access',
    text: 'If you are a VHA team member, you will need access to VHA-specific' +
    ' pages to perform your duties. Press the “Request access” button below to' +
    ' be redirected to the VHA section within the Help page, where you can' +
    ' submit a form for access.'
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
          Request Access
        </Button>
      </div>
    </Alert>
  );
};

VHAOrgJoinInfo.propTypes = {
  VHAOrgJoinInfoCode: PropTypes.string,
};
