import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';

import { connect } from 'react-redux';
import { getWorksheet } from '../actions/Dockets';
import LoadingContainer from '../../components/LoadingContainer';
import StatusMessage from '../../components/StatusMessage';
import { LOGO_COLORS } from '../../constants/AppConstants';
import { SERVER_ERROR_CODES } from '../constants/constants';
import HearingWorksheet from '../HearingWorksheet';
import querystring from 'querystring';
import { getQueryParams } from '../../util/QueryParamsUtil';

const PRINT_WINDOW_TIMEOUT_IN_MS = 150;

export class HearingWorksheetContainer extends React.Component {

  componentDidMount() {
    if (!this.props.worksheet) {
      this.props.getWorksheet(this.props.hearingId);
    }
  }

  componentWillReceiveProps(nextProps) {
    if (!nextProps.worksheetServerError.errors && ((!nextProps.fetchingWorksheet &&
        !nextProps.worksheet) || (this.props.hearingId !== nextProps.hearingId))) {
      this.props.getWorksheet(nextProps.hearingId);
    }
  }

  componentDidUpdate() {
    // We use the `do_not_open_print_prompt` querystring option for testing,
    // since Selenium struggles to interact with browser UI like a print prompt.
    const query = querystring.parse(window.location.search.slice(1));

    if (this.props.worksheet && this.props.print && !query.do_not_open_print_prompt) {
      window.onafterprint = this.afterPrint;
      setTimeout(() => {
        window.print();
      }, PRINT_WINDOW_TIMEOUT_IN_MS);
    }
  }

  afterPrint = () => {
    const params = getQueryParams(window.location.search);

    if (params.keep_open !== 'true') {
      window.close();
    }
  }

  render() {

    const { worksheetServerError } = this.props;

    /* handling 404 error messages */
    if (worksheetServerError.errors &&
        worksheetServerError.errors[0] &&
        worksheetServerError.errors[0].code === SERVER_ERROR_CODES.VACOLS_RECORD_DOES_NOT_EXIST) {
      return <StatusMessage
        title="No hearing held">
          The Veteran was scheduled for a hearing, however, their case was<br />
          removed from the Daily Docket before the hearing date.
      </StatusMessage>;
    } else if (worksheetServerError.errors) {
      return <StatusMessage
        title="Unable to load the worksheet">
          It looks like Caseflow was unable to load the worksheet.<br />
          Please <a href="">refresh the page</a> and try again.
      </StatusMessage>;
    }

    if (!this.props.worksheet) {
      return <div className="loading-hearings">
        <div className="cf-sg-loader">
          <LoadingContainer color={LOGO_COLORS.HEARINGS.ACCENT}>
            <div className="cf-image-loader">
            </div>
            <p className="cf-txt-c">Loading worksheet, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    return <HearingWorksheet {...this.props} history={this.context.router.history} />;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.hearings.worksheet,
  worksheetServerError: state.hearings.worksheetServerError,
  fetchingWorksheet: state.hearings.fetchingWorksheet
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    getWorksheet
  }, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetContainer);

HearingWorksheetContainer.propTypes = {
  hearingId: PropTypes.string.isRequired
};

HearingWorksheetContainer.contextTypes = {
  router: PropTypes.object.isRequired
};
