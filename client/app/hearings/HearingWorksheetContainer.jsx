import React from 'react';
import PropTypes from 'prop-types';
import { connect } from 'react-redux';
import * as Actions from './actions/Dockets';
import LoadingContainer from '../components/LoadingContainer';
import * as AppConstants from '../constants/AppConstants';
import HearingWorksheet from './HearingWorksheet';
import ApiUtil from '../util/ApiUtil';

// TODO: method should get data to populate worksheet
export const getWorksheet = (id, dispatch) => {
  ApiUtil.get(`/hearings/${id}/worksheet.json`, { cache: true }).
    then((response) => {
      dispatch(Actions.populateWorksheet(response.body));
    }, (err) => {
      dispatch(Actions.handleServerError(err));
    });
};

export class HearingWorksheetContainer extends React.Component {

  componentDidMount() {
    // TODO: if !worksheet call this.props.getWorksheet
    if (!this.props.worksheet) {
      this.props.getWorksheet(this.props.hearingId);
    }
  }

  render() {

    if (this.props.serverError) {
      return <div style={{ textAlign: 'center' }}>
        An error occurred while retrieving your hearings.</div>;
    }

    if (!this.props.worksheet) {
      return <div className="loading-hearings">
        <div className="cf-sg-loader">
          <LoadingContainer color={AppConstants.LOADING_INDICATOR_COLOR_HEARINGS}>
              <div className="cf-image-loader">
              </div>
            <p className="cf-txt-c">Loading worksheet, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    return <HearingWorksheet
      {...this.props}
    />;
  }
}

const mapStateToProps = (state) => ({
  // TODO: add mappings
  worksheet: state.worksheet
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
  hearingId: PropTypes.string.isRequired
};
