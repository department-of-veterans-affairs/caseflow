import pluralize from 'pluralize';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import CaseListTable from './CaseListTable';
import { fullWidth } from './constants';

import { clearCaseListSearch, onReceiveAppealsUsingVeteranId } from './CaseList/CaseListActions';
import { appealsByCaseflowVeteranId } from './selectors';

import COPY from '../../COPY.json';

class CaseListView extends React.PureComponent {
  componentWillUnmount = () => this.props.clearCaseListSearch();

  createLoadPromise = () => {
    if (this.props.appeals.length) {
      return Promise.resolve();
    }

    const caseflowVeteranId = this.props.caseflowVeteranId;

    return ApiUtil.get(`/cases/${caseflowVeteranId}`).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        this.props.onReceiveAppealsUsingVeteranId(returnedObject.appeals);
      });
  };

  caseListTable = () => {
    const appealsCount = this.props.appeals.length;

    if (!appealsCount) {
      return null;
    }

    // Using the first appeal in the list to get the Veteran's name and ID. We expect that data to be
    // the same for all appeals in the list.
    const firstAppeal = this.props.appeals[0];
    const heading = `${appealsCount} ${pluralize('case', appealsCount)} found for
        “${firstAppeal.veteranFullName} (${firstAppeal.veteranFileNumber})”`;

    return <div>
      <h1 className="cf-push-left" {...fullWidth}>{heading}</h1>
      <CaseListTable appeals={this.props.appeals} />
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

const mapStateToProps = (state, ownProps) => ({
  appeals: appealsByCaseflowVeteranId(state, { caseflowVeteranId: ownProps.caseflowVeteranId })
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  clearCaseListSearch,
  onReceiveAppealsUsingVeteranId
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(CaseListView);
