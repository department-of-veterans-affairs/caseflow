import { css } from 'glamor';
import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import COPY from '../../COPY';

import { clearCaseListSearch, appealsSearch, setCaseListSearch } from './CaseList/CaseListActions';

import CaseSearchErrorMessage from './CaseSearchErrorMessage';
import SearchBar from '../components/SearchBar';

const alertBoxStyling = css({ marginBottom: '3rem' });

class CaseListSearch extends React.PureComponent {
  onSubmitSearch = (searchQuery) => {
    /* eslint-disable no-empty-function */
    // Error cases already handled inside the promise itself.
    this.props.
      appealsSearch(searchQuery).
      then((veteranIds) => {
        const caseListPath = `/search?veteran_ids=${veteranIds.join(',')}`;

        if (this.props.location.pathname === '/schedule') {
          return (window.location = caseListPath);
        }

        return this.props.history.push(caseListPath);
      }).
      catch(() => {});
    /* eslint-enable no-empty-function */
  };

  render() {
    return (
      <React.Fragment>
        <div {...alertBoxStyling}>
          <CaseSearchErrorMessage />
        </div>
        <SearchBar
          id={this.props.elementId}
          size={this.props.searchSize}
          onChange={this.props.setCaseListSearch}
          value={this.props.caseList.caseListCriteria.searchQuery}
          onClearSearch={this.props.clearCaseListSearch}
          onSubmit={this.onSubmitSearch}
          loading={this.props.caseList.isRequestingAppealsUsingVeteranId}
          submitUsingEnterKey
          placeholder={this.props.placeholder}
        />
      </React.Fragment>
    );
  }
}

CaseListSearch.propTypes = {
  elementId: PropTypes.string,
  searchSize: PropTypes.string,
  placeholder: PropTypes.string,
  caseList: PropTypes.object,
  appealsSearch: PropTypes.func,
  setCaseListSearch: PropTypes.func,
  clearCaseListSearch: PropTypes.func,
  match: PropTypes.object,
  location: PropTypes.object.isRequired,
  history: PropTypes.object.isRequired
};

CaseListSearch.defaultProps = {
  elementId: 'searchBar',
  searchSize: 'big',
  placeholder: COPY.CASE_SEARCH_INPUT_PLACEHOLDER
};

const mapDispatchToProps = (dispatch) =>
  bindActionCreators(
    {
      clearCaseListSearch,
      appealsSearch,
      setCaseListSearch
    },
    dispatch
  );

const mapStateToProps = (state) => ({
  caseList: state.caseList
});

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CaseListSearch)
);
