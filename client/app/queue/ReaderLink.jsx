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

const newFileIconStyling = css({
  paddingLeft: '.75rem'
});

export default class ReaderLink extends React.PureComponent {
  readerLinkAnalytics = () => {
    window.analyticsEvent(this.props.analyticsSource, TASK_ACTIONS.QUEUE_TO_READER);
  }

  render = () => {
    const {
      redirectUrl,
      taskType,
      appealId,
      appeal,
      docCountWithinLink,
      docCountBelowLink,
      cached,
      newDocsIcon,
      onHoldDate
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
          View { docCountWithinLink && <AppealDocumentCount appeal={appeal} cached={cached} /> } docs
        { newDocsIcon && <span {...newFileIconStyling}>
          <NewFile externalAppealId={appeal.externalId} cached={cached} onHoldDate={onHoldDate} /></span> }</Link>
      { docCountBelowLink &&
            <div {...documentCountSizeStyling}>
              <AppealDocumentCount loadingText appeal={appeal} cached={cached} />
            </div>
      }
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
  appealId: PropTypes.string.isRequired,
  cached: PropTypes.bool,
  newDocsIcon: PropTypes.bool
};

ReaderLink.defaultProps = {
  docCountWithinLink: false,
  docCountBelowLink: false
};
