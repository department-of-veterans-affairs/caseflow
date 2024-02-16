import React from 'react';
import PropTypes from 'prop-types';
import querystring from 'querystring';
import { connect } from 'react-redux';

import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import Badge from '../components/badges/Badge';

import { TASK_ACTIONS } from './constants';
import { COLORS } from 'app/constants/AppConstants';

import AppealDocumentCount from './AppealDocumentCount';
import { css } from 'glamor';

const documentCountSizeStyling = css({
  fontSize: '.9em'
});

const badgeStyling = css({
  display: 'inline-block',
});

class ReaderLink extends React.PureComponent {

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
      docCountBelowLink
    } = this.props;
    const linkProps = {};

    const veteranInaccessibleTooltip = (appeal) => {
      return <Badge
        name="inaccessible"
        displayName="!"
        color={COLORS.GOLD_LIGHTER}
        tooltipText="<Inaccessible veteran text>"
        id={`inaccess-${appeal.id}`}
        ariaLabel="inaccessible vet"
      />;
    }

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
      <Link disabled={!this.props.isVeteranAccessible} href="#" {...linkProps} onClick={this.readerLinkAnalytics}>
          View { docCountWithinLink && <AppealDocumentCount appeal={appeal} /> } docs</Link>
      { !this.props.isVeteranAccessible && <span {...badgeStyling}>{ veteranInaccessibleTooltip(appeal) }</span> }

      { docCountBelowLink &&
            <div {...documentCountSizeStyling}>
              <AppealDocumentCount loadingText appeal={appeal} />
            </div>
      }
    </React.Fragment>;
  };
}

ReaderLink.propTypes = {
  analyticsSource: PropTypes.string,
  appeal: PropTypes.object.isRequired,
  task: PropTypes.object,
  docCountWithinLink: PropTypes.bool,
  docCountBelowLink: PropTypes.bool,
  redirectUrl: PropTypes.string,
  taskType: PropTypes.string,
  appealId: PropTypes.string.isRequired,
  newDocsIcon: PropTypes.bool,
  isVeteranAccessible: PropTypes.bool
};

ReaderLink.defaultProps = {
  docCountWithinLink: false,
  docCountBelowLink: false,
  task: null,
  isVeteranAccessible: false
};

const mapStateToProps = (state, ownProps) => {
  const externalId = ownProps.appeal.externalId;

  return {
    isVeteranAccessible: state.queue.docCountForAppeal[externalId]?.isVeteranAccessible || false
  };
};

export default connect(mapStateToProps)(ReaderLink);
