import React from 'react';
import { LOGO_COLORS } from '../../constants/AppConstants';
import PropTypes from 'prop-types';
import { populateWorksheet } from '../actions/hearingWorksheetActions';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';
import HearingWorksheet from '../components/hearingWorksheet/HearingWorksheet';
import HearingWorksheetPrinted from '../components/hearingWorksheet/HearingWorksheetPrinted';

class HearingWorksheetContainer extends React.Component {

  loadHearingWorksheet = () => {
    let requestUrl = `/hearings/${this.props.hearingId}/worksheet.json`;

    return ApiUtil.get(requestUrl).then((response) => {
      this.props.populateWorksheet(response.body);
    });
  };

  render() {
    return (
      <React.Fragment>
        <LoadingDataDisplay
          createLoadPromise={this.loadHearingWorksheet}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
            message: 'Loading the hearing worksheet...'
          }}
          failStatusMessageProps={{
            title: 'Unable to load the hearing worksheet.'
          }}
        >
          {
            this.props.print ? <HearingWorksheetPrinted /> : <HearingWorksheet />
          }
        </LoadingDataDisplay>
      </React.Fragment>
    );
  }
}

HearingWorksheetContainer.propTypes = {
  hearingId: PropTypes.string.isRequired,
  print: PropTypes.bool
};

const mapDispatchToProps = (dispatch) => bindActionCreators({
  populateWorksheet
}, dispatch);

export default connect(null, mapDispatchToProps)(HearingWorksheetContainer);
