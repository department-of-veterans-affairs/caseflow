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
      return 'your cases';
    }

    if (!veteranFullName) {
      return queueTaskType;
    }

    return `${veteranFullName} (${vbmsId})`;
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
        to={useReactRouter ? queueRedirectUrl : ''}
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
  useReactRouter: PropTypes.bool,
  collapseTopMargin: PropTypes.string
};

export default BackToQueueLink;
