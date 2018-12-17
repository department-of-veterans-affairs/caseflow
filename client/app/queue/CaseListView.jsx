import pluralize from 'pluralize';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';
import _ from 'lodash';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import {
  COLORS,
  LOGO_COLORS
} from '../constants/AppConstants';
import CaseListSearch from './CaseListSearch';
import CaseListTable from './CaseListTable';
import OtherReviewsTable from './OtherReviewsTable';
import { fullWidth } from './constants';

import {
  onReceiveAppealsUsingVeteranId,
  onReceiveClaimReviewsUsingVeteranId
} from './CaseList/CaseListActions';
import {
  appealsByCaseflowVeteranId,
  claimReviewsByCaseflowVeteranId
} from './selectors';

import COPY from '../../COPY.json';

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '5rem',
  marginBottom: '5rem'
});

class CaseListView extends React.PureComponent {
  createLoadPromise = () => {
    const caseflowVeteranId = this.props.caseflowVeteranId;

    if (this.props.appeals.length || !caseflowVeteranId) {
      return Promise.resolve();
    }

    return ApiUtil.get(`/cases/${caseflowVeteranId}`).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        const claimReviews = returnedObject.claim_reviews.map((review) => {
          return {
            ...review,
            caseflow_veteran_id: this.props.caseflowVeteranId
          };
        });

        this.props.onReceiveAppealsUsingVeteranId(returnedObject.appeals);
        this.props.onReceiveClaimReviewsUsingVeteranId(claimReviews);
      });
  };

  searchPageHeading = () => <React.Fragment>
    <h1 className="cf-push-left" {...fullWidth}>{COPY.CASE_SEARCH_HOME_PAGE_HEADING}</h1>
    <p>{COPY.CASE_SEARCH_INPUT_INSTRUCTION}</p>
    <CaseListSearch elementId="searchBarEmptyList" />
  </React.Fragment>;

  caseListTable = () => {
    let otherReviewsTable;
    const appealsCount = this.props.appeals.length;

    if (!appealsCount) {
      return <div>
        {this.searchPageHeading()}
        <hr {...horizontalRuleStyling} />
        <p><Link href="/help">Caseflow Help</Link></p>
      </div>;
    }

    const claimReviewsCount = this.props.claimReviews && this.props.claimReviews.length;

    if (claimReviewsCount) {
      otherReviewsTable = <OtherReviewsTable reviews={this.props.claimReviews} />;
    }

    // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
    // the same for all appeals in the list.
    const firstAppeal = this.props.appeals[0];
    const heading = `${appealsCount} ${pluralize('case', appealsCount)} found for
        “${firstAppeal.veteranFullName} (${firstAppeal.veteranFileNumber})”`;

    return <div>
      {this.searchPageHeading()}
      <br /><br />
      <h2 className="cf-push-left" {...fullWidth}>{heading}</h2>

      <h3 className="cf-push-left" {...fullWidth}>Appeals</h3>
      <CaseListTable appeals={this.props.appeals} />

      <h3 className="cf-push-left" {...fullWidth}>Other Decision Reviews</h3>
      {otherReviewsTable}
    </div>;
  }

  render() {
    const failStatusMessageChildren = <div>
      Caseflow was unable to load cases.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
    </div>;

    return <AppSegment filledBackground>
      <LoadingDataDisplay
        createLoadPromise={this.createLoadPromise}
        loadingComponentProps={{
          spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
          message: COPY.CASE_SEARCH_DATA_LOAD_IN_PROGRESS_MESSAGE
        }}
        failStatusMessageProps={{ title: COPY.CASE_SEARCH_DATA_LOAD_FAILED_MESSAGE }}
        failStatusMessageChildren={failStatusMessageChildren}>
        {this.caseListTable()}
      </LoadingDataDisplay>
    </AppSegment>;
  }
}

CaseListView.propTypes = {
  caseflowVeteranId: PropTypes.string
};

CaseListView.defaultProps = {
  caseflowVeteranId: ''
};

const mapStateToProps = (state, ownProps) => {
  return {
    appeals: appealsByCaseflowVeteranId(state, { caseflowVeteranId: ownProps.caseflowVeteranId }),
    claimReviews: claimReviewsByCaseflowVeteranId(state, { caseflowVeteranId: ownProps.caseflowVeteranId })
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAppealsUsingVeteranId,
  onReceiveClaimReviewsUsingVeteranId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
