import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';

import CaseListSearch from './CaseListSearch';

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
  render = () => <div className="section-search" {...searchStyling(this.props.isRequestingAppealsUsingVeteranId)}>
    <CaseListSearch />
  </div>;
}

const mapStateToProps = (state) => ({
  isRequestingAppealsUsingVeteranId: state.caseList.isRequestingAppealsUsingVeteranId
});

export default connect(mapStateToProps)(SearchBar);
