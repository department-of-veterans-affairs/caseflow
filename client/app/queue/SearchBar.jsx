import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';

import CaseListSearch from './CaseListSearch';
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

class SearchBar extends React.PureComponent {
  render() {
    // TODO: Move this container div inside of CaseListSearch and ger rid of this component once everybody is
    // use queue_case_search.
    if (this.props.shouldUseQueueCaseSearch) {
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
}

SearchBar.propTypes = {
  feedbackUrl: PropTypes.string.isRequired,
  shouldUseQueueCaseSearch: PropTypes.bool.isRequired
};

const mapStateToProps = (state) => ({
  isRequestingAppealsUsingVeteranId: state.caseList.isRequestingAppealsUsingVeteranId
});

export default connect(mapStateToProps)(SearchBar);
