import { css } from 'glamor';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';

import CaseListSearch from './CaseListSearch';
import CaseListTable from './CaseListTable';
import { fullWidth, SEARCH_ERROR_FOR } from './constants';

import { clearCaseListSearch } from './CaseList/CaseListActions';

import COPY from '../../../COPY.json';

const backLinkStyling = css({
  float: 'left',
  marginTop: '-3rem'
});

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '5rem',
  marginBottom: '5rem'
});

class CaseListView extends React.PureComponent {
  shouldShowBreadcrumbs = () => this.props.caseList.receivedAppeals.length > 0 || this.props.errorType;

  render() {
    const body = {
      heading: 'Veteran Case Search',
      component: <React.Fragment>
        <p>Enter a 9-digit Veteran ID to search for all available cases for a Veteran</p>
        <CaseListSearch elementId="searchBarEmptyList" />
        <hr {...horizontalRuleStyling} />
        <p><Link to="/help">Caseflow Help</Link></p>
      </React.Fragment>
    };

    const appealsCount = this.props.caseList.receivedAppeals.length;

    if (appealsCount > 0) {
      // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
      // the same for all appeals in the list.
      const firstAppeal = this.props.caseList.receivedAppeals[0];

      body.heading = `${appealsCount} ${pluralize('case', appealsCount)} found for
          “${firstAppeal.attributes.veteran_full_name} (${firstAppeal.attributes.vbms_id})”`;
      body.component = <CaseListTable appeals={this.props.caseList.receivedAppeals} />;
    }

    if (this.props.errorType) {
      let errorMessage = COPY.CASE_SEARCH_INPUT_INSTRUCTION;

      switch (this.props.errorType) {
      case SEARCH_ERROR_FOR.INVALID_VETERAN_ID:
        body.heading = sprintf(COPY.CASE_SEARCH_ERROR_INVALID_ID_HEADING, this.props.queryResultingInError);
        break;
      case SEARCH_ERROR_FOR.NO_APPEALS:
        body.heading = sprintf(COPY.CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, this.props.queryResultingInError);
        break;
      case SEARCH_ERROR_FOR.UNKNOWN_SERVER_ERROR:
      default:
        body.heading = sprintf(COPY.CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, this.props.queryResultingInError);
        errorMessage = COPY.CASE_SEARCH_ERROR_UNKNOWN_ERROR_MESSAGE;
      }

      body.component = <React.Fragment>
        <p>{errorMessage}</p>
        <CaseListSearch elementId="searchBarEmptyList" />
      </React.Fragment>;
    }

    return <React.Fragment>
      { this.shouldShowBreadcrumbs() &&
        <div {...backLinkStyling}>
          <Link to={this.props.backLinkTarget} onClick={this.props.clearCaseListSearch}>{this.props.backLinkText}</Link>
        </div>
      }
      <AppSegment filledBackground>
        <div>
          <h1 className="cf-push-left" {...fullWidth}>{body.heading}</h1>
          {body.component}
        </div>
      </AppSegment>
    </React.Fragment>;
  }
}

CaseListView.propTypes = {
  backLinkTarget: PropTypes.string,
  backLinkText: PropTypes.string
};

CaseListView.defaultProps = {
  backLinkTarget: '/queue',
  backLinkText: COPY.BACK_TO_PERSONAL_QUEUE_LINK_LABEL
};

const mapStateToProps = (state) => ({
  caseList: state.caseList,
  errorType: state.caseList.search.errorType,
  queryResultingInError: state.caseList.search.queryResultingInError,
  searchQuery: state.caseList.caseListCriteria.searchQuery
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
