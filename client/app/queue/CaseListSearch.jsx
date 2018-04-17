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
    return <SearchBar
      id={this.props.elementId}
      size={this.props.searchSize}
      onChange={this.props.setCaseListSearch}
      value={this.props.caseList.caseListCriteria.searchQuery}
      onClearSearch={this.props.clearCaseListSearch}
      onSubmit={this.onSubmitSearch}
      loading={this.props.caseList.isRequestingAppealsUsingVeteranId}
      submitUsingEnterKey
    />;
  }
}

CaseListSearch.propTypes = {
  elementId: PropTypes.string,
  searchSize: PropTypes.string
};

CaseListSearch.defaultProps = {
  elementId: 'searchBar',
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
