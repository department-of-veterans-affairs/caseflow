import React from 'react';
import PropTypes from 'prop-types';
import querystring from 'querystring';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { TASK_ACTIONS } from './constants';

import NewFile from './components/NewFile';
import AppealDocumentCount from './AppealDocumentCount';
import { css } from 'glamor';

const documentCountSizeStyling = css({
  fontSize: '.9em'
});

export default class ReaderLink extends React.PureComponent {
  readerLinkAnalytics = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.QUEUE_TO_READER);
  }

  getLinkText = () => {
    const {
      appeal,
      docCountWithinLink,
      docCountBelowLink
    } = this.props;

    return <React.Fragment>
      <React.Fragment>View { docCountWithinLink && <AppealDocumentCount appeal={this.props.appeal} /> } docs
      <NewFile externalAppealId={appeal.externalId} /></React.Fragment>
      { docCountBelowLink &&
        <div {...documentCountSizeStyling}>
          <AppealDocumentCount loadingText appeal={this.props.appeal} />
        </div>
      }
    </React.Fragment>;
  };

  getAppealDocumentCount = () => {
    return <AppealDocumentCount appeal={this.props.appeal} />;
  }

  render = () => {
    const {
      redirectUrl,
      taskType,
      appealId
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

      linkProps.href = `/reader/appeal/${appealId}/documents?${qs}`;
    } else {
      linkProps.disabled = true;
    }

    return <React.Fragment>
      <Link {...linkProps} onClick={this.readerLinkAnalytics}>
        {this.getLinkText()}
      </Link>
    </React.Fragment>;
  };
}

ReaderLink.propTypes = {
  analyticsSource: PropTypes.string,
  appeal: PropTypes.object.isRequired,
  docCountWithinLink: PropTypes.bool,
  docCountBelowLink: PropTypes.bool,
  redirectUrl: PropTypes.string,
  taskType: PropTypes.string,
  appealId: PropTypes.string.isRequired
};

ReaderLink.defaultProps = {
  docCountWithinLink: false,
  docCountBelowLink: false
};
