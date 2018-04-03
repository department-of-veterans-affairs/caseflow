import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { fullWidth } from './constants';
import QueueTable from './QueueTable';

// TODO: Add breadcrumbs.
class SearchEnabledView extends React.PureComponent {
  // TODO: What is the search results error behaviour here?
  // As written if a search errored, the child would return to being displayed and the error would show above the list.
  // Do we want to have the previous search to stick around?
  render() {
    // TODO: Pass the list of receivedAppeals to QueueList
    if (this.props.caseSelect.shouldUseQueueSearch && this.props.caseSelect.receivedAppeals.length > 0) {
      return <AppSegment filledBackground>
        <div>
          <h1 className="cf-push-left" {...fullWidth}>Cases found for ...</h1>
          <QueueTable />
        </div>
      </AppSegment>;
    }

    return this.props.children;
  };
}

const mapStateToProps = (state) => ({ caseSelect: state.caseSelect });

export default connect(mapStateToProps)(SearchEnabledView);
