import React from 'react';
import { LOGO_COLORS } from '../../constants/AppConstants';
import PropTypes from 'prop-types';
import { populateWorksheet } from '../../hearings/actions/Dockets';
import { bindActionCreators } from 'redux';
import connect from 'react-redux/es/connect/connect';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import ApiUtil from '../../util/ApiUtil';
import HearingWorksheet from '../../hearings/HearingWorksheet';
import { openPrintDialogue } from '../../util/PrintUtil';

class HearingWorksheetContainer extends React.Component {

  componentDidMount() {
    if (this.props.print) {
      openPrintDialogue();
    }
  }

  loadHearingWorksheet = () => {
    let requestUrl = `/hearings/${this.props.hearingId}/worksheet.json`;

    return ApiUtil.get(requestUrl).then((response) => {
      this.props.populateWorksheet(response.body);
    });
  };

  createHearingPromise = () => Promise.all([
    this.loadHearingWorksheet()
  ]);

  render() {
    return (
      <React.Fragment>
        <LoadingDataDisplay
          createLoadPromise={this.createHearingPromise}
          loadingComponentProps={{
            spinnerColor: LOGO_COLORS.HEARINGS.ACCENT,
            message: 'Loading the hearing worksheet...'
          }}
          failStatusMessageProps={{
            title: 'Unable to load the hearing worksheet.'
          }}>
          <HearingWorksheet
            print={this.props.print}
          />
        </LoadingDataDisplay>
      </React.Fragment>
    );
  }
}

HearingWorksheetContainer.propTypes = {
  hearingId: PropTypes.string.isRequired,
  print: PropTypes.bool
};

const mapStateToProps = (state) => ({
  worksheet: state.hearings.worksheet
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  populateWorksheet
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(HearingWorksheetContainer);
