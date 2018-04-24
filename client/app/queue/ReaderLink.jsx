import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import querystring from 'querystring';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { TASK_ACTIONS } from './constants';

export default class ReaderLink extends React.PureComponent {

  readerLinkAnalytics = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.QUEUE_TO_READER);
  }

  getLinkText = () => {
    const {
      docCount,
      longMessage,
      message
    } = this.props;

    if (message) {
      return message;
    }

    if (_.isNumber(docCount)) {
      const cnt = docCount.toLocaleString();

      return longMessage ? `Open ${cnt} documents in Caseflow Reader` : `View ${cnt} in Reader`;
    }

    return longMessage ? 'Open documents in Caseflow Reader' : 'View in Reader';
  };

  render = () => {
    const {
      redirectUrl,
      taskType,
      taskId,
      vacolsId
    } = this.props;
    const linkProps = {};

    if (taskId) {
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
  docCount: PropTypes.string,
  longMessage: PropTypes.bool,
  redirectUrl: PropTypes.string,
  taskId: PropTypes.string,
  taskType: PropTypes.string,
  vacolsId: PropTypes.string.isRequired
};

ReaderLink.defaultProps = {
  longMessage: false
};
