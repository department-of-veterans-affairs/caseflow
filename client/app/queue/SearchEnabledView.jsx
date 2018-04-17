import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';

import CaseListSearch from './CaseListSearch';
import CaseListView from './CaseListView';
import CaseSelectSearch from '../reader/CaseSelectSearch';

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

class SearchEnabledView extends React.PureComponent {
  searchBar() {
    if (this.props.shouldUseQueueCaseSearch) {
      // Do not draw the search bar in the top left when the search caused an error.
      if (this.props.errorType) {
        return;
      }

      return <div className="section-search" {...searchStyling(this.props.isRequestingAppealsUsingVeteranId)}>
        <CaseListSearch />
      </div>;
    }

    return <CaseSelectSearch
      navigateToPath={(path) => {
        const redirectUrl = encodeURIComponent(window.location.pathname);

        location.href = `/reader/appeal${path}?queue_redirect_url=${redirectUrl}`;
      }}
      alwaysShowCaseSelectionModal
      feedbackUrl={this.props.feedbackUrl}
      searchSize="big"
      styling={searchStyling(this.props.isRequestingAppealsUsingVeteranId)} />;
  }

  render() {
    const {
      appeals,
      errorType,
      shouldUseQueueCaseSearch
    } = this.props;

    return <React.Fragment>
      { this.searchBar() }
      { shouldUseQueueCaseSearch && (appeals.length > 0 || errorType) ? <CaseListView /> : this.props.children }
    </React.Fragment>;
  }
}

SearchEnabledView.propTypes = {
  feedbackUrl: PropTypes.string.isRequired,
  shouldUseQueueCaseSearch: PropTypes.bool.isRequired
};

const mapStateToProps = (state) => ({
  appeals: state.caseList.receivedAppeals,
  errorType: state.caseList.search.errorType,
  isRequestingAppealsUsingVeteranId: state.caseList.isRequestingAppealsUsingVeteranId
});

export default connect(mapStateToProps)(SearchEnabledView);
