import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';

import CaseListSearch from './CaseListSearch';
import CaseListView from './CaseListView';

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
  render() {
    const {
      appealCount,
      feedbackUrl,
      isRequestingAppealsUsingVeteranId,
      shouldUseAppealSearch
    } = this.props;

    return <React.Fragment>
      <CaseListSearch
        navigateToPath={(path) => {
          const redirectUrl = encodeURIComponent(window.location.pathname);

          location.href = `/reader/appeal${path}?queue_redirect_url=${redirectUrl}`;
        }}
        alwaysShowCaseSelectionModal
        feedbackUrl={feedbackUrl}
        searchSize="big"
        styling={searchStyling(isRequestingAppealsUsingVeteranId)} />
      { shouldUseAppealSearch && appealCount > 0 ? <CaseListView /> : this.props.children }
    </React.Fragment>;
  }
}

SearchEnabledView.propTypes = {
  feedbackUrl: PropTypes.string.isRequired
};

const mapStateToProps = (state) => ({
  appealCount: state.caseList.receivedAppeals.length,
  isRequestingAppealsUsingVeteranId: state.caseList.isRequestingAppealsUsingVeteranId,
  shouldUseAppealSearch: state.caseList.shouldUseAppealSearch
});

export default connect(mapStateToProps)(SearchEnabledView);
