import React from 'react';
import { connect } from 'react-redux';
import { withRouter } from 'react-router-dom';
import { bindActionCreators } from 'redux';
import PropTypes from 'prop-types';
import COPY from '../../COPY';

class CaseListLoadMore extends React.PureComponent {
  render() {
    return (
      <React.Fragment>
        { COPY.CASE_SEARCH_LOAD_MORE_TEXT }
      </React.Fragment>
    );
  }
}

CaseListLoadMore.propTypes = {
  caseListCount: PropTypes.number
};

CaseListLoadMore.defaultProps = {
  caseListCount: 0
};

const mapDispatchToProps = (dispatch) => bindActionCreators({}, dispatch);

const mapStateToProps = (state) => ({ caseList: state.caseList });

export default withRouter(
  connect(
    mapStateToProps,
    mapDispatchToProps
  )(CaseListLoadMore)
);
