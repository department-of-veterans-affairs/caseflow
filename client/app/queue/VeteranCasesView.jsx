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

import COPY from '../../COPY.json';

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
  marginBottom: '0 !important'
});

class VeteranCasesView extends React.PureComponent {
  componentWillUnmount = () => this.props.hideVeteranCaseList();

  createLoadPromise = () => {
    const { veteranId } = this.props;

    return ApiUtil.get('/appeals', { headers: { 'veteran-id': veteranId } }).
      then((response) => {
        const returnedObject = JSON.parse(response.text);

        if (!returnedObject.appeals.length) {
          return Promise.reject(response);
        }

        this.props.setFetchedAllCasesFor(veteranId, returnedObject.appeals);

        return Promise.resolve();
      });
  }

  caseListTable = () => <div {...containerStyling}>
    <h2>All Cases</h2>
    <CaseListTable appeals={this.props.appeals[this.props.veteranId]} styling={caseListStyling} />
  </div>;

  render() {
    // Do not display the loading spinner if we already have the cases.
    if (this.props.veteranId in this.props.appeals) {
      return this.caseListTable();
    }

    const failStatusMessageChildren = <div>
      Caseflow was unable to load cases.<br />
      Please <a onClick={this.reload}>refresh the page</a> and try again.
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
  veteranId: PropTypes.string
};

VeteranCasesView.defaultProps = {
  veteranId: ''
};

const mapStateToProps = (state) => ({
  appeals: state.caseList.casesForVeteran
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  setFetchedAllCasesFor,
  hideVeteranCaseList
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(VeteranCasesView);
