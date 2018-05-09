import React from 'react';
import PropTypes from 'prop-types';
import querystring from 'querystring';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { TASK_ACTIONS } from './constants';
import AppealDocumentCount from './AppealDocumentCount';

export default class ReaderLink extends React.PureComponent {

  readerLinkAnalytics = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.QUEUE_TO_READER);
  }

  getLinkText = () => {
    const {
      appeal,
      longMessage,
      message
    } = this.props;

    if (message) {
      return message;
    }

    return longMessage ?
      <React.Fragment>Open <AppealDocumentCount appeal={appeal} /> documents in Caseflow Reader</React.Fragment> :
      <React.Fragment>View <AppealDocumentCount appeal={appeal} /> in Reader</React.Fragment>;
  };

  render = () => {
    const {
      redirectUrl,
      taskType,
      vacolsId
    } = this.props;
    const linkProps = {};

    if (redirectUrl) {
      const queryParams = {
        queue_redirect_url: redirectUrl
      };

      if (taskType) {
        queryParams.queue_task_type = taskType;
      }
      const qs = querystring.stringify(queryParams);

      linkProps.href = `/reader/appeal/${vacolsId}/documents?${qs}`;
    } else {
      linkProps.disabled = true;
    }

    return <Link {...linkProps} onClick={this.readerLinkAnalytics}>
      {this.getLinkText()}
    </Link>;
  };
}

ReaderLink.propTypes = {
  analyticsSource: PropTypes.string,
  appeal: PropTypes.object.isRequired,
  longMessage: PropTypes.bool,
  redirectUrl: PropTypes.string,
  taskType: PropTypes.string,
  vacolsId: PropTypes.string.isRequired
};

ReaderLink.defaultProps = {
  longMessage: false
};
