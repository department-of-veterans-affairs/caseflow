import React from 'react';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import { useSelector } from 'react-redux';
import { isEmpty } from 'lodash';

const PendingIssueModificationBanner = () => {
  const pendingIssueModificationRequests = useSelector((state) => state.pendingIssueModificationRequests);

  return (
    !isEmpty(pendingIssueModificationRequests) && <div>
      <Alert type="info"
        title={COPY.PENDING_ISSUE_MODIFICATION_REQUESTS_BANNER_TITLE}>
        {COPY.PENDING_ISSUE_MODIFICATION_REQUESTS_BANNER_MESSAGE}
      </Alert>
    </div>
  );
};

export default PendingIssueModificationBanner;
