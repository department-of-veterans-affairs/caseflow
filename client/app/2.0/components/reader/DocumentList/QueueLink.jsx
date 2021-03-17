import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

// Local Dependencies
import { queueLinkStyles } from 'styles/reader/DocumentList';
import { formatRedirectText } from 'utils/reader';

/**
 * Queue Link Component
 * @param {Object} props -- React Props for the Queue Link Component
 */
export const QueueLink = ({ useReactRouter, queueRedirectUrl, queueTaskType, veteranFullName, vbmsId }) => (
  <div {...queueLinkStyles}>
    <Link
      to={useReactRouter ? queueRedirectUrl : ''}
      href={useReactRouter ? '' : queueRedirectUrl}>
      {formatRedirectText({ queueTaskType, veteranFullName, vbmsId })}
    </Link>
  </div>
);

QueueLink.propTypes = {
  queueRedirectUrl: PropTypes.string.isRequired,
  vbmsId: PropTypes.string,
  veteranFullName: PropTypes.string,
  queueTaskType: PropTypes.string,
  useReactRouter: PropTypes.bool,
  collapseTopMargin: PropTypes.string
};

export default QueueLink;
