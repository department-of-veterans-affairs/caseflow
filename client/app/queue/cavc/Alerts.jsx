import React from 'react';
import { css } from 'glamor';

import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';

const bottomInfoStyling = css({ marginBottom: '4rem' });

export const JmrIssuesBanner = React.memo(() => (
  <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.JMR_SELECTION_ISSUE_INFO_BANNER}
  </Alert>
));
export const JmprIssuesBanner = React.memo(() => (
  <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.JMPR_SELECTION_ISSUE_INFO_BANNER}
  </Alert>
));
export const MdrIssuesBanner = React.memo(() => (
  <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.MDR_SELECTION_ISSUE_INFO_BANNER}
  </Alert>
));

export const MdrBanner = React.memo(() => (
  <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.MDR_SELECTION_ALERT_BANNER}
  </Alert>
));
export const NoMandateBanner = React.memo(() => (
  <Alert type="info" styling={bottomInfoStyling} scrollOnAlert={false}>
    {COPY.CAVC_REMAND_NO_MANDATE_TEXT}
  </Alert>
));
