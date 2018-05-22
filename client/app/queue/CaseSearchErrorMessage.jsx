import React from 'react';
import { connect } from 'react-redux';
import { sprintf } from 'sprintf-js';

import Alert from '../components/Alert';
import { SEARCH_ERROR_FOR } from './constants';
import COPY from '../../../COPY.json';

class CaseSearchErrorMessage extends React.PureComponent {
  render() {
    if (!this.props.errorType) {
      return null;
    }

    let title = null;
    let message = COPY.CASE_SEARCH_INPUT_INSTRUCTION;

    switch (this.props.errorType) {
    case SEARCH_ERROR_FOR.EMPTY_SEARCH_TERM:
      title = COPY.CASE_SEARCH_ERROR_EMPTY_SEARCH_TERM;
      break;
    case SEARCH_ERROR_FOR.INVALID_VETERAN_ID:
      title = sprintf(COPY.CASE_SEARCH_ERROR_INVALID_ID_HEADING, this.props.queryResultingInError);
      break;
    case SEARCH_ERROR_FOR.NO_APPEALS:
      title = sprintf(COPY.CASE_SEARCH_ERROR_NO_CASES_FOUND_HEADING, this.props.queryResultingInError);
      break;
    case SEARCH_ERROR_FOR.UNKNOWN_SERVER_ERROR:
    default:
      title = sprintf(COPY.CASE_SEARCH_ERROR_UNKNOWN_ERROR_HEADING, this.props.queryResultingInError);
      message = COPY.CASE_SEARCH_ERROR_UNKNOWN_ERROR_MESSAGE;
    }

    return <Alert title={title} type="error">{message}</Alert>;
  }
}

const mapStateToProps = (state) => ({
  errorType: state.caseList.search.errorType,
  queryResultingInError: state.caseList.search.queryResultingInError
});

export default connect(mapStateToProps)(CaseSearchErrorMessage);
