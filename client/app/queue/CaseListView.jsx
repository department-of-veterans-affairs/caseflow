import _ from 'lodash';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import ApiUtil from '../util/ApiUtil';
import WindowUtil from '../util/WindowUtil';
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
  onReceiveAppeals,
  onReceiveClaimReviews
} from './CaseList/CaseListActions';
import {
  appealsByCaseflowVeteranId,
  claimReviewsByCaseflowVeteranId
} from './selectors';
import COPY from '../../COPY';
import Alert from '../components/Alert';

const horizontalRuleStyling = css({
  border: 0,
  borderTop: `1px solid ${COLORS.GREY_LIGHT}`,
  marginTop: '5rem',
  marginBottom: '5rem'
});

class CaseListView extends React.PureComponent {
  constructor(props) {
    super(props);
    const alert = sessionStorage.getItem('veteranSearchPageAlert');

    if (alert) {
      sessionStorage.removeItem('veteranSearchPageAlert');
    }
    this.state = { alert: JSON.parse(alert) };
  }

  createLoadPromise = () => {
    const { appeals, claimReviews, caseflowVeteranIds } = this.props;

    if (!_.isEmpty(appeals) || !_.isEmpty(claimReviews) || _.isEmpty(caseflowVeteranIds)) {
      return Promise.resolve();
    }

    return ApiUtil.get('/search', { query: { veteran_ids: caseflowVeteranIds.join(',') } }).
      then((response) => {
        this.props.onReceiveAppeals(response.body.appeals);
        this.props.onReceiveClaimReviews(response.body.claim_reviews);
      });
  };

  searchPageHeading = () => <React.Fragment>
    <h1 className="cf-push-left" {...fullWidth}>{COPY.CASE_SEARCH_HOME_PAGE_HEADING}</h1>
    <p>{COPY.CASE_SEARCH_INPUT_INSTRUCTION}</p>
    <CaseListSearch elementId="searchBarEmptyList" />
  </React.Fragment>;

  caseListTable = () => {
    let heading;
    const appealsCount = this.props.appeals.length;
    const claimReviewsCount = this.props.claimReviews.length;
    const doesSearchHaveAnyResults = (appealsCount + claimReviewsCount > 0);

    if (!doesSearchHaveAnyResults) {
      return <div>
        {this.searchPageHeading()}
        <hr {...horizontalRuleStyling} />
        <p><Link href="/help">Caseflow Help</Link></p>
      </div>;
    }

    // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
    // the same for all appeals in the list.
    if (this.props.appeals.length > 0) {
      const firstAppeal = this.props.appeals[0];

      heading = `${appealsCount} ${pluralize('case', appealsCount)} found for
          “${firstAppeal.veteranFullName} (${firstAppeal.veteranFileNumber})”`;
    } else if (this.props.claimReviews.length > 0) {
      const firstClaimReview = this.props.claimReviews[0];

      heading = `No cases found for “${firstClaimReview.veteranFullName} (${firstClaimReview.veteranFileNumber})”`;
    }

    return <React.Fragment>
      <div>
        {this.searchPageHeading()}
        <br /><br />
        <h2 className="cf-push-left" {...fullWidth}>{heading}</h2>

        <h3 className="cf-push-left" {...fullWidth}>{COPY.CASE_LIST_TABLE_TITLE}</h3>
        <CaseListTable appeals={this.props.appeals} />

        <h3 className="cf-push-left" {...fullWidth}>{COPY.OTHER_REVIEWS_TABLE_TITLE}</h3>
        <OtherReviewsTable reviews={this.props.claimReviews} />
      </div>
    </React.Fragment>;
  }

  render() {
    const failStatusMessageChildren = <div>
      Caseflow was unable to load cases.<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
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
        {!_.isEmpty(this.state.alert) && (
          <Alert type={this.state.alert.type} title={this.state.alert.title} scrollOnAlert={false}>
            {this.state.alert.detail}
          </Alert>
        )}
        {this.caseListTable()}
      </LoadingDataDisplay>
    </AppSegment>;
  }
}

CaseListView.propTypes = {
  appeals: PropTypes.arrayOf(PropTypes.object),
  caseflowVeteranIds: PropTypes.arrayOf(PropTypes.string),
  claimReviews: PropTypes.arrayOf(PropTypes.object),
  onReceiveAppeals: PropTypes.func,
  onReceiveClaimReviews: PropTypes.func,
};

CaseListView.defaultProps = {
  caseflowVeteranIds: []
};

const mapStateToProps = (state, ownProps) => {
  const caseflowVeteranIds = ownProps.caseflowVeteranIds || [];
  const appeals = caseflowVeteranIds.flatMap(
    (id) => appealsByCaseflowVeteranId(state, { caseflowVeteranId: id })
  );
  const claimReviews = caseflowVeteranIds.flatMap(
    (id) => claimReviewsByCaseflowVeteranId(state, { caseflowVeteranId: id })
  );

  return {
    appeals,
    claimReviews,
  };
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveAppeals,
  onReceiveClaimReviews
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
