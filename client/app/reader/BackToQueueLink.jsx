import React from 'react';
import PropTypes from 'prop-types';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

class BackToQueueLink extends React.PureComponent {
  getRedirectText = () => {
    const {
      queueTaskType,
      veteranFullName,
      vbmsId
    } = this.props;

    if (!queueTaskType) {
      return 'Your Queue';
    }

    if (!veteranFullName) {
      return queueTaskType;
    }

    return  `${queueTaskType} - ${veteranFullName} (${vbmsId})`;
  }

  render = () => {
    const {
      queueRedirectUrl,
      collapseTopMargin,
      useReactRouter
    } = this.props;

    const segmentStyling = css({
      marginTop: collapseTopMargin ? '-1.5rem' : '1.5rem',
      marginBottom: '-1.5rem'
    });

    return <div {...segmentStyling}>
      <Link
        to={useReactRouter? queueRedirectUrl : ''}
        href={useReactRouter ? '' : queueRedirectUrl}>
          &lt; Back to {this.getRedirectText()}
      </Link>
    </div>;
  }
}

BackToQueueLink.propTypes = {
  queueRedirectUrl: PropTypes.string.isRequired,
  vbmsId: PropTypes.string,
  veteranFullName: PropTypes.string,
  queueTaskType: PropTypes.string,
  useReactRouter: PropTypes.boolean
};

export default BackToQueueLink;
