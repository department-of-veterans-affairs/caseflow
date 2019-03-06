import React from 'react';
import PropTypes from 'prop-types';
import { bindActionCreators } from 'redux';
import { connect } from 'react-redux';
import _ from 'lodash';
import { getDailyDocket,
  handleSaveHearingSuccess,
  handleSaveHearingError,
  resetSaveHearingSuccess,
  resetSaveHearingError
} from '../actions/Dockets';
import ApiUtil from '../../util/ApiUtil';
import LoadingContainer from '../../components/LoadingContainer';
import StatusMessage from '../../components/StatusMessage';
import { LOGO_COLORS } from '../../constants/AppConstants';
import DailyDocket from '../DailyDocket';
import { getDate } from '../util/DateUtil';
import { css } from 'glamor';

const alertStyling = css({
  marginTop: '2rem'
});

export class DailyDocketContainer extends React.Component {

  componentDidMount() {
    this.props.getDailyDocket(null, this.props.date);
    document.title += ` ${getDate(this.props.date)}`;
  }

  componentDidUpdate = (prevProps) => {
    if (!((_.isNil(prevProps.saveHearingSuccess) && this.props.saveHearingSuccess) ||
      _.isNil(this.props.saveHearingSuccess))) {
      this.props.resetSaveHearingSuccess();
    }
    if (!((_.isNil(prevProps.saveHearingError) && this.props.saveHearingError) ||
      _.isNil(this.props.saveHearingError))) {
      this.props.resetSaveHearingError();
    }
  };

  saveHearing = (hearing) => () => {
    ApiUtil.patch(`/hearings/${hearing.external_id}`, { data: {
      hearing
    } }).
      then((response) => {
        this.props.handleSaveHearingSuccess(JSON.parse(response.text), this.props.date);
      }, (err) => {
        this.props.handleSaveHearingError(err);
      });
  };

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

    return <div>
      <div className="cf-hearings-daily-docket-container" {...alertStyling}>
        <DailyDocket
          veteran_law_judge={this.props.veteran_law_judge}
          date={this.props.date}
          docket={dailyDocket}
          hearingDay={this.props.hearingDay}
          saveHearing={this.saveHearing}
          saveHearingSuccess={this.props.saveHearingSuccess}
          saveHearingError={this.props.saveHearingError}
        />
      </div>
    </div>;
  }
}

const mapStateToProps = (state) => ({
  dailyDocket: state.dailyDocket,
  hearingDay: state.hearingDay,
  docketServerError: state.docketServerError,
  saveHearingSuccess: state.saveHearingSuccess,
  saveHearingError: state.saveHearingError
});

const mapDispatchToProps = (dispatch) => ({
  ...bindActionCreators({
    getDailyDocket,
    handleSaveHearingSuccess,
    handleSaveHearingError,
    resetSaveHearingSuccess,
    resetSaveHearingError
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
