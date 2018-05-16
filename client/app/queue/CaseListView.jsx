import { css } from 'glamor';
import pluralize from 'pluralize';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { sprintf } from 'sprintf-js';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import CaseListSearch from './CaseListSearch';
import CaseListTable from './CaseListTable';
import { fullWidth } from './constants';

import { clearCaseListSearch } from './CaseList/CaseListActions';

import COPY from '../../../COPY.json';

const backLinkStyling = css({
  float: 'left',
  marginTop: '-3rem'
});

// TODO: Wrap this in LoadingDataDisplay to request by caseflowVeteranId in case we are navigating to this URL directly.
// We do something in efolder, check that out to see how we handled that situation.
class CaseListView extends React.PureComponent {
  render() {
    // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
    // the same for all appeals in the list.
    const firstAppeal = this.props.appeals[0];
    const appealsCount = this.props.appeals.length;
    const heading = `${appealsCount} ${pluralize('case', appealsCount)} found for
        “${firstAppeal.attributes.veteran_full_name} (${firstAppeal.attributes.vbms_id})”`;

    return <React.Fragment>
      <div {...backLinkStyling}>
        <Link to={this.props.backLinkTarget} onClick={this.props.clearCaseListSearch}>{this.props.backLinkText}</Link>
      </div>
      <AppSegment filledBackground>
        <div>
          <h1 className="cf-push-left" {...fullWidth}>{heading}</h1>
          <CaseListTable appeals={this.props.appeals} />
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
  appeals: state.caseList.receivedAppeals
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
