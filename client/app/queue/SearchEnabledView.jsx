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
  render() {
    const {
      displayCaseListResults,
      feedbackUrl,
      isRequestingAppealsUsingVeteranId,
      shouldUseQueueCaseSearch
    } = this.props;

    return <React.Fragment>
      { shouldUseQueueCaseSearch ? <CaseListSearch styling={searchStyling(isRequestingAppealsUsingVeteranId)} /> :
        <CaseSelectSearch
          navigateToPath={(path) => {
            const redirectUrl = encodeURIComponent(window.location.pathname);

            location.href = `/reader/appeal${path}?queue_redirect_url=${redirectUrl}`;
          }}
          alwaysShowCaseSelectionModal
          feedbackUrl={feedbackUrl}
          searchSize="big"
          styling={searchStyling(isRequestingAppealsUsingVeteranId)} />
      }
      { shouldUseQueueCaseSearch && displayCaseListResults ? <CaseListView /> : this.props.children }
    </React.Fragment>;
  }
}

SearchEnabledView.propTypes = {
  feedbackUrl: PropTypes.string.isRequired,
  shouldUseQueueCaseSearch: PropTypes.bool.isRequired
};

const mapStateToProps = (state) => ({
  displayCaseListResults: state.caseList.displayCaseListResults,
  isRequestingAppealsUsingVeteranId: state.caseList.isRequestingAppealsUsingVeteranId
});

export default connect(mapStateToProps)(SearchEnabledView);
