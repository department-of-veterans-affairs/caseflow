import React from 'react';

import Alert from 'app/components/Alert';
import {
  CASE_DETAILS_VSO_VISIBILITY_ALERT_TITLE,
  CASE_DETAILS_VSO_VISIBILITY_ALERT_MESSAGE,
} from 'app/../COPY';

export const VsoVisibilityAlert = (props) => (
  <Alert
    type="info"
    title={CASE_DETAILS_VSO_VISIBILITY_ALERT_TITLE}
    message={CASE_DETAILS_VSO_VISIBILITY_ALERT_MESSAGE}
    {...props}
  />
);
