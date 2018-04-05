import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import CaseListTable from './CaseListTable';
import { fullWidth } from './constants';

// TODO: Add breadcrumbs.
class SearchEnabledView extends React.PureComponent {
  // TODO: What is the search results error behaviour here?
  // As written if a search errored, the child would return to being displayed and the error would show above the list.
  // Do we want to have the previous search to stick around?
  render() {
    // TODO: Pass the list of receivedAppeals to QueueList
    if (this.props.caseList.shouldUseAppealSearch && this.props.caseList.receivedAppeals.length > 0) {
      return <AppSegment filledBackground>
        <div>
          <h1 className="cf-push-left" {...fullWidth}>Cases found for ...</h1>
          <CaseListTable appeals={this.props.caseList.receivedAppeals} />
        </div>
      </AppSegment>;
    }

    return this.props.children;
  };
}

const mapStateToProps = (state) => ({ caseList: state.caseList });

export default connect(mapStateToProps)(SearchEnabledView);
