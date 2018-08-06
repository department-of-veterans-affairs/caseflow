import PropTypes from 'prop-types';
import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';

import LoadingDataDisplay from '../components/LoadingDataDisplay';
import { LOGO_COLORS } from '../constants/AppConstants';
import CaseListTable from './CaseListTable';
import { fetchCasesForVeteran } from './CaseList/CaseListActions';

import COPY from '../../COPY.json';

class VeteranCasesView extends React.PureComponent {
  createLoadPromise = () => {
    if (this.props.requestInProgress) {
      return Promise.resolve();
    }

    return this.props.fetchCasesForVeteran(this.props.veteranId);
  };

  caseListTable = () => <CaseListTable appeals={this.props.appeals[this.props.veteranId]} />;

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
  appeals: state.caseList.casesForVeteran,
  requestInProgress: state.caseList.isRequestingCasesForVeteran
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  fetchCasesForVeteran
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(VeteranCasesView);
