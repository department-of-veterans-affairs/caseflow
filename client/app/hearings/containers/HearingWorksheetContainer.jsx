import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from '../actions/Dockets';
import LoadingContainer from '../../components/LoadingContainer';
import StatusMessage from '../../components/StatusMessage';
import { LOGO_COLORS } from '../../constants/AppConstants';
import HearingWorksheet from '../HearingWorksheet';
import ApiUtil from '../../util/ApiUtil';
import querystring from 'querystring';

export const getWorksheet = (id, dispatch) => {
  ApiUtil.get(`/hearings/${id}/worksheet.json`, { cache: true }).
    then((response) => {
      dispatch(Actions.populateWorksheet(response.body));
    }, (err) => {
      dispatch(Actions.handleWorksheetServerError(err));
    });
};

export class HearingWorksheetContainer extends React.Component {

  componentDidMount() {
    if (!this.props.worksheet) {
      this.props.getWorksheet(this.props.hearingId);
    }
  }

  componentDidUpdate() {
    // We use the `do_not_open_print_prompt` querystring option for testing,
    // since Selenium struggles to interact with browser UI like a print prompt.
    const query = querystring.parse(window.location.search.slice(1));

    if (this.props.worksheet && this.props.print && !query.do_not_open_print_prompt) {
      window.print();
    }
  }

  render() {

    if (this.props.worksheetServerError) {
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

    return <HearingWorksheet {...this.props} />;
  }
}

const mapStateToProps = (state) => ({
  worksheet: state.worksheet,
  worksheetServerError: state.worksheetServerError
});

const mapDispatchToProps = (dispatch) => ({
  getWorksheet: (id) => {
    getWorksheet(id, dispatch);
  }
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(HearingWorksheetContainer);

HearingWorksheetContainer.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  hearingId: PropTypes.string.isRequired,
  worksheetServerError: PropTypes.object
};
