import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';

import {
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch
} from './CaseList/CaseListActions';

import CaseSearchErrorMessage from './CaseSearchErrorMessage';
import SearchBar from '../components/SearchBar';

class CaseListSearch extends React.PureComponent {
  onSubmitSearch = (searchQuery) => {
    /* eslint-disable no-empty-function */
    // Error cases already handled inside the promise itself.
    this.props.fetchAppealsUsingVeteranId(searchQuery).then((id) => this.props.history.push(`/cases/${id}`)).
      catch(() => {});
    /* eslint-enable no-empty-function */
  }

  render() {
    return <React.Fragment>
      <CaseSearchErrorMessage />
      <SearchBar
        id={this.props.elementId}
        size={this.props.searchSize}
        onChange={this.props.setCaseListSearch}
        value={this.props.caseList.caseListCriteria.searchQuery}
        onClearSearch={this.props.clearCaseListSearch}
        onSubmit={this.onSubmitSearch}
        loading={this.props.caseList.isRequestingAppealsUsingVeteranId}
        submitUsingEnterKey
      />
    </React.Fragment>;
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

export default withRouter(connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseListSearch));
