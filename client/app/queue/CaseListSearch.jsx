import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import PropTypes from 'prop-types';

import {
  clearCaseListSearch,
  emptyQuerySearchAttempt,
  fetchAppealUsingVeteranIdFailed,
  fetchAppealUsingInvalidVeteranIdFailed,
  fetchedNoAppealsUsingVeteranId,
  onReceiveAppealsUsingVeteranId,
  requestAppealUsingVeteranId,
  setCaseListSearch
} from './CaseList/CaseListActions';

import CaseSearchErrorMessage from './CaseSearchErrorMessage';
import SearchBar from '../components/SearchBar';
import ApiUtil from '../util/ApiUtil';

class CaseListSearch extends React.PureComponent {
  onSubmitSearch = (searchQuery) => {
    if (!searchQuery.length) {
      this.props.emptyQuerySearchAttempt();

      return;
    }

    // Allow for SSNs (9 digits) as well as claims file numbers (7 or 8 digits).
    const veteranId = searchQuery.replace(/\D/g, '');

    if (!veteranId.match(/\d{7,9}/)) {
      this.props.fetchAppealUsingInvalidVeteranIdFailed(searchQuery);

      return;
    }

    this.props.requestAppealUsingVeteranId();
    ApiUtil.get('/appeals', {
      headers: { 'veteran-id': veteranId }
    }).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        if (_.size(returnedObject.appeals) === 0) {
          this.props.fetchedNoAppealsUsingVeteranId(veteranId);
        } else {
          this.props.onReceiveAppealsUsingVeteranId(returnedObject.appeals);

          // Expect all of the appeals will be for the same Caseflow Veteran ID so we pull off the first for the URL.
          const caseflowVeteranId = returnedObject.appeals[0].attributes.caseflow_veteran_id;

          this.props.history.push(`/cases/${caseflowVeteranId}`);
        }
      }, () => {
        this.props.fetchAppealUsingVeteranIdFailed(searchQuery);
      });
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
  emptyQuerySearchAttempt,
  fetchAppealUsingVeteranIdFailed,
  fetchAppealUsingInvalidVeteranIdFailed,
  fetchedNoAppealsUsingVeteranId,
  onReceiveAppealsUsingVeteranId,
  requestAppealUsingVeteranId,
  setCaseListSearch
}, dispatch);

const mapStateToProps = (state) => ({
  caseList: state.caseList
});

export default withRouter(connect(
  mapStateToProps,
  mapDispatchToProps
)(CaseListSearch));
