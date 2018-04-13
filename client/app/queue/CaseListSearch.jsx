import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import PropTypes from 'prop-types';

import {
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch
} from './CaseList/CaseListActions';
import SearchBar from '../components/SearchBar';

class CaseListSearch extends React.PureComponent {
  onSubmitSearch = (text) => {
    if (_.size(text)) {
      this.props.fetchAppealsUsingVeteranId(text);
    }
  }

  render() {
    const { caseList } = this.props;

    const topSearchBar = () => {
      // Hide the search bar when displaying an error on the search results page.
      if (caseList.displayCaseListResults &&
        (caseList.search.showErrorMessage || caseList.search.queryResultingInError)) {
        return;
      }

      return <SearchBar
        id="searchBar"
        size={this.props.searchSize}
        onChange={this.props.setCaseListSearch}
        value={caseList.caseListCriteria.searchQuery}
        onClearSearch={this.props.clearCaseListSearch}
        onSubmit={this.onSubmitSearch}
        loading={caseList.isRequestingAppealsUsingVeteranId}
        submitUsingEnterKey
      />;
    };

    return <div className="section-search" {...this.props.styling}>
      { topSearchBar() }
    </div>;
  }
}

CaseListSearch.propTypes = {
  searchSize: PropTypes.string,
  styling: PropTypes.object
};

CaseListSearch.defaultProps = {
  searchSize: 'big'
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch
}, dispatch);

const mapStateToProps = (state) => ({
  caseList: state.caseList
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseListSearch);
