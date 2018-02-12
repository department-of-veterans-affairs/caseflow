import React from 'react';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

const segmentStyling = css({
  marginTop: '3rem'
});

const TASK_TYPE_CODES = {
  "dd": "Draft Decision"
};

class BackToQueueLink extends React.PureComponent {
  getRedirectText = () => {
    const {
      taskCode,
      veteranFullName,
      vbmsId,
    } = this.props;

    if (taskCode && TASK_TYPE_CODES[taskCode]) {
      return `${TASK_TYPE_CODES[taskCode]} - ${veteranFullName} (${vbmsId})`
    }
    return 'Your Queue';
  }

  render = () => {
    const {
      queueRedirectUrl
    } = this.props;

    return <div {...segmentStyling}>
      <Link href={queueRedirectUrl}>&lt; Back to {this.getRedirectText()}</Link>
    </div>;
  }
}

export default BackToQueueLink;
