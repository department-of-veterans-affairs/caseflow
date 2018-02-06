import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

const segmentStyling = css({
  marginTop: '3rem'
});

const BackToQueueLink = ({ queueRedirectUrl }) =>
  <div {...segmentStyling}>
    <Link href={queueRedirectUrl}>&lt; Back to Your Queue</Link>
  </div>;

export default BackToQueueLink;
