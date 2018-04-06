import { css } from 'glamor';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import CaseListSearch from './CaseListSearch';
import CaseListTable from './CaseListTable';
import { fullWidth } from './constants';

const searchStyling = (isRequestingAppealsUsingVeteranId) => css({
  '.section-search': {
    '& .usa-alert-info, & .usa-alert-error': {
      marginBottom: '1.5rem',
      marginTop: 0
    },
    '& .cf-search-input-with-close': {
      marginLeft: `calc(100% - ${isRequestingAppealsUsingVeteranId ? '60' : '56.5'}rem)`
    },
    '& .cf-submit': {
      width: '10.5rem'
    }
  }
});

// TODO: Add breadcrumbs.
class SearchEnabledView extends React.PureComponent {
  viewBody = () => {
    const appealsCount = this.props.caseList.receivedAppeals.length;

    if (this.props.caseList.shouldUseAppealSearch && appealsCount > 0) {
      // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
      // the same for all appeals in the list.
      const firstAppeal = this.props.caseList.receivedAppeals[0];
      const docCount = this.props.caseList.documentCountForVeteran;

      return <AppSegment filledBackground>
        <div>
          <h1 className="cf-push-left" {...fullWidth}>
            {appealsCount} {pluralize('case', appealsCount)} found for "{firstAppeal.attributes.veteran_full_name} ({firstAppeal.attributes.vbms_id})"
          </h1>
          <p>View { docCount && `${docCount} ` }documents in Caseflow Reader</p>
          <CaseListTable appeals={this.props.caseList.receivedAppeals} />
        </div>
      </AppSegment>;
    }

    return this.props.children;
  }

  // TODO: What is the search results error behaviour here?
  // As written if a search errored, the child would return to being displayed and the error would show above the list.
  // Do we want to have the previous search stick around?
  render() {
    return <React.Fragment>
      <CaseListSearch
        navigateToPath={(path) => {
          const redirectUrl = encodeURIComponent(window.location.pathname);

          location.href = `/reader/appeal${path}?queue_redirect_url=${redirectUrl}`;
        }}
        alwaysShowCaseSelectionModal
        feedbackUrl={this.props.feedbackUrl}
        searchSize="big"
        styling={searchStyling(this.props.isRequestingAppealsUsingVeteranId)} />
        { this.viewBody() }
      </React.Fragment>;
  };
}

SearchEnabledView.propTypes = {
  feedbackUrl: PropTypes.string.isRequired
};

const mapStateToProps = (state) => ({
  caseList: state.caseList,
  isRequestingAppealsUsingVeteranId: state.caseList.isRequestingAppealsUsingVeteranId
});

export default connect(mapStateToProps)(SearchEnabledView);
