import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

const segmentStyling = css({
  marginTop: '3rem'
});

class BackToQueueLink extends React.PureComponent {
  getRedirectText = () => {
    const {
      queueTaskType,
      veteranFullName,
      vbmsId
    } = this.props;

    if (queueTaskType) {
      return `${queueTaskType} - ${veteranFullName} (${vbmsId})`;
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

BackToQueueLink.propTypes = {
  queueRedirectUrl: PropTypes.string.isRequired,
  vbmsId: PropTypes.string,
  veteranFullName: PropTypes.string,
  queueTaskType: PropTypes.string
};

export default BackToQueueLink;
