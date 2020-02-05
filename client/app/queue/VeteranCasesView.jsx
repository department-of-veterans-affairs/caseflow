import { css } from 'glamor';
import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import ApiUtil from '../util/ApiUtil';
import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { COLORS, LOGO_COLORS } from '../constants/AppConstants';
import CaseListTable from './CaseListTable';
import { setFetchedAllCasesFor } from './CaseList/CaseListActions';
import { hideVeteranCaseList } from './uiReducer/uiActions';
import { onReceiveAppealDetails } from './QueueActions';
import { appealsByCaseflowVeteranId } from './selectors';
import { prepareAppealForStore } from './utils';

import COPY from '../../COPY';
import WindowUtil from '../util/WindowUtil';

const containerStyling = css({
  backgroundColor: COLORS.GREY_BACKGROUND,
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  borderBottom: 0,
  borderRadius: '0.5rem 0.5rem 0 0',
  marginTop: '3rem',
  '& > h2': {
    marginBottom: '-3rem',
    padding: '1rem 2rem'
  }
});

const caseListStyling = css({
  marginBottom: '0 !important',
  '& td:first-child, th:first-child': {
    paddingLeft: '1rem'
  }
});

class VeteranCasesView extends React.PureComponent {
  componentWillUnmount = () => this.props.hideVeteranCaseList();

  createLoadPromise = () => {
    const { caseflowVeteranId, veteranId } = this.props;

    return ApiUtil.get('/appeals', { headers: { 'case-search': veteranId } }).
      then((response) => {
        const returnedObject = response.body;

        if (!returnedObject.appeals.length) {
          return Promise.reject(response);
        }

        this.props.onReceiveAppealDetails(prepareAppealForStore(returnedObject.appeals));
        this.props.setFetchedAllCasesFor(caseflowVeteranId);

        return Promise.resolve();
      });
  }

  caseListTable = () => <div {...containerStyling}>
    <h2>All Cases</h2>
    <CaseListTable appeals={this.props.appeals} styling={caseListStyling} />
  </div>;

  render() {
    // Do not display the loading spinner if we already have the cases.
    if (this.props.caseflowVeteranId in this.props.fetchedAllCasesFor) {
      return this.caseListTable();
    }

    const failStatusMessageChildren = <div>
      Caseflow was unable to load cases.<br />
      Please <a onClick={WindowUtil.reloadWithPOST}>refresh the page</a> and try again.
    </div>;

    return <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.QUEUE.ACCENT,
        message: COPY.CASE_SEARCH_DATA_LOAD_IN_PROGRESS_MESSAGE
      }}
      failStatusMessageProps={{ title: COPY.CASE_SEARCH_DATA_LOAD_FAILED_MESSAGE }}
      failStatusMessageChildren={failStatusMessageChildren}>
      {this.caseListTable()}
    </LoadingDataDisplay>;
  }
}

VeteranCasesView.propTypes = {
  appeals: PropTypes.arrayOf(PropTypes.object),
  caseflowVeteranId: PropTypes.number,
  fetchedAllCasesFor: PropTypes.object,
  hideVeteranCaseList: PropTypes.func,
  onReceiveAppealDetails: PropTypes.func,
  setFetchedAllCasesFor: PropTypes.func,
  veteranId: PropTypes.string
};

VeteranCasesView.defaultProps = {
  caseflowVeteranId: 0,
  veteranId: ''
};

const mapStateToProps = (state, ownProps) => ({
  appeals: appealsByCaseflowVeteranId(state, { caseflowVeteranId: ownProps.caseflowVeteranId }),
  fetchedAllCasesFor: state.caseList.fetchedAllCasesFor
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  hideVeteranCaseList,
  onReceiveAppealDetails,
  setFetchedAllCasesFor
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(VeteranCasesView);
