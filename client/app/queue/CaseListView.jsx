import { css } from 'glamor';
import _ from 'lodash';
import pluralize from 'pluralize';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import CaseListTable from './CaseListTable';
import SearchBar from '../components/SearchBar';
import { fullWidth } from './constants';

import {
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch
} from './CaseList/CaseListActions';

const backLinkStyling = css({
  float: 'left',
  marginTop: '-3rem'
});

class CaseListView extends React.PureComponent {
  searchOnChange = (text) => {
    if (_.size(text)) {
      this.props.fetchAppealsUsingVeteranId(text);
    }
  }

  pageBody = () => {
    const appealsCount = this.props.caseList.receivedAppeals.length;

    if (appealsCount > 0) {
      // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
      // the same for all appeals in the list.
      const firstAppeal = this.props.caseList.receivedAppeals[0];

      return <React.Fragment>
        <h1 className="cf-push-left" {...fullWidth}>
          {appealsCount} {pluralize('case', appealsCount)} found for&nbsp;
          “{firstAppeal.attributes.veteran_full_name} ({firstAppeal.attributes.vbms_id})”
        </h1>
        <CaseListTable appeals={this.props.caseList.receivedAppeals} />
      </React.Fragment>;
    }

    return <React.Fragment>
      <h1 className="cf-push-left" {...fullWidth}>No cases found for “{this.props.searchQuery}”</h1>
      <p>Please enter a valid 9-digit Veteran ID to search for all available cases.</p>
      <SearchBar
        id="searchBarEmptyList"
        size="big"
        onChange={this.props.setCaseListSearch}
        value={this.props.caseList.caseListCriteria.searchQuery}
        onClearSearch={this.props.clearCaseListSearch}
        onSubmit={this.searchOnChange}
        loading={this.props.caseList.isRequestingAppealsUsingVeteranId}
        submitUsingEnterKey
      />
    </React.Fragment>;
  }

  // TODO: What is the search results error behaviour here?
  // As written if a search errored, the child would return to being displayed and the error would show above the list.
  // Do we want to have the previous search stick around?
  render() {
    return <React.Fragment>
      <div {...backLinkStyling}>
        <Link to="/" onClick={this.props.clearCaseListSearch}>&lt; Back to Your Queue</Link>
      </div>
      <AppSegment filledBackground>
        <div>
          { this.pageBody() }
        </div>
      </AppSegment>
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  caseList: state.caseList,
  searchQuery: state.caseList.caseListCriteria.searchQuery
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch,
  fetchAppealsUsingVeteranId,
  setCaseListSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
