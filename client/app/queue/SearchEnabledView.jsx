import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';

import CaseListView from './CaseListView';
import SearchBar from './SearchBar';

class SearchEnabledView extends React.PureComponent {
  render() {
    const {
      appeals,
      errorType,
      shouldUseQueueCaseSearch
    } = this.props;

    return <React.Fragment>
      <SearchBar feedbackUrl={this.props.feedbackUrl} shouldUseQueueCaseSearch={this.props.shouldUseQueueCaseSearch} />
      { shouldUseQueueCaseSearch && (appeals.length > 0 || errorType) ? <CaseListView /> : this.props.children }
    </React.Fragment>;
  }
}

SearchEnabledView.propTypes = {
  feedbackUrl: PropTypes.string.isRequired,
  shouldUseQueueCaseSearch: PropTypes.bool.isRequired
};

const mapStateToProps = (state) => ({
  appeals: state.caseList.receivedAppeals,
  errorType: state.caseList.search.errorType
});

export default connect(mapStateToProps)(SearchEnabledView);
