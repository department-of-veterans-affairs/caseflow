import { css } from 'glamor';
import pluralize from 'pluralize';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import CaseListTable from './CaseListTable';
import { fullWidth } from './constants';

import { clearCaseListSearch } from './CaseList/CaseListActions';

const backLinkStyling = css({
  float: 'left',
  marginTop: '-3rem'
});

class CaseListView extends React.PureComponent {
  // TODO: What is the search results error behaviour here?
  // As written if a search errored, the child would return to being displayed and the error would show above the list.
  // Do we want to have the previous search stick around?
  render() {
    const appealsCount = this.props.caseList.receivedAppeals.length;

    // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
    // the same for all appeals in the list.
    const firstAppeal = this.props.caseList.receivedAppeals[0];
    const docCount = this.props.caseList.documentCountForVeteran;

    return <React.Fragment>
      <div {...backLinkStyling}>
        <Link to="/" onClick={this.props.clearCaseListSearch}>&lt; Back to Your Queue</Link>
      </div>
      <AppSegment filledBackground>
        <div>
          <h1 className="cf-push-left" {...fullWidth}>
            {appealsCount} {pluralize('case', appealsCount)} found for “{firstAppeal.attributes.veteran_full_name} ({firstAppeal.attributes.vbms_id})”
          </h1>
          <CaseListTable appeals={this.props.caseList.receivedAppeals} />
        </div>
      </AppSegment>
    </React.Fragment>;
  }
}

const mapStateToProps = (state) => ({
  caseList: state.caseList
});

const mapDispatchToProps = (dispatch) => bindActionCreators({ clearCaseListSearch }, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
