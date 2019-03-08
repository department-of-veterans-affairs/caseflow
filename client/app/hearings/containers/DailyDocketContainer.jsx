import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import { getDailyDocket, saveDocket } from '../actions/Dockets';
import _ from 'lodash';
import LoadingContainer from '../../components/LoadingContainer';
import StatusMessage from '../../components/StatusMessage';
import { LOGO_COLORS } from '../../constants/AppConstants';
import AutoSave from '../../components/AutoSave';
import DailyDocket from '../DailyDocket';
import { getDate, now } from '../util/DateUtil';
import { css } from 'glamor';

const alertStyling = css({
  marginTop: '2rem'
});

export class DailyDocketContainer extends React.Component {

  componentDidMount() {
    this.props.getDailyDocket(null, this.props.date);
    document.title += ` ${getDate(this.props.date)}`;
  }

  render() {

    const dailyDocket = this.props.dailyDocket[this.props.date];

    if (this.props.docketServerError) {
      return <StatusMessage
        title= "Unable to load hearings">
          It looks like Caseflow was unable to load hearings.<br />
          Please <a href="">refresh the page</a> and try again.
      </StatusMessage>;
    }

    if (!dailyDocket) {
      return <div className="loading-hearings">
        <div className="cf-sg-loader">
          <LoadingContainer color={LOGO_COLORS.HEARINGS.ACCENT}>
            <div className="cf-image-loader">
            </div>
            <p className="cf-txt-c">Loading hearings, please wait...</p>
          </LoadingContainer>
        </div>
      </div>;
    }

    if (_.isEmpty(dailyDocket)) {
      return <div>You have no hearings on this date.</div>;
    }

    return <div>

      <AutoSave
        save={this.props.saveDocket(_.values(dailyDocket), this.props.date)}
        spinnerColor={LOGO_COLORS.HEARINGS.ACCENT}
        isSaving={this.props.docketIsSaving}
        timeSaved={this.props.docketTimeSaved || now()}
        saveFailed={this.props.saveDocketFailed}
      />
      <div className="cf-hearings-daily-docket-container" {...alertStyling}>
        <DailyDocket
          veteran_law_judge={this.props.veteran_law_judge}
          date={this.props.date}
          docket={dailyDocket}
          hearingDay={this.props.hearingDay}
        />
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.dailyDocket,
  hearingDay: state.hearingDay,
  docketServerError: state.docketServerError,
  docketIsSaving: state.docketIsSaving,
  docketTimeSaved: state.docketTimeSaved,
  saveDocketFailed: state.saveDocketFailed
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    getDailyDocket,
    saveDocket
  }, dispatch)
});

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(DailyDocketContainer);

DailyDocketContainer.propTypes = {
  veteran_law_judge: PropTypes.object.isRequired,
  dailyDocket: PropTypes.object,
  date: PropTypes.string.isRequired,
  docketServerError: PropTypes.object
};
