import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import _ from 'lodash';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { onRegionalOfficeChange, onReceiveUpcomingHearingDays } from '../actions';
import AssignHearings from '../components/AssignHearings';

class AssignHearingsContainer extends React.PureComponent {

  componentDidUpdate = (prevProps) => {
    if (this.props.selectedRegionalOffice !== prevProps.selectedRegionalOffice) {
      this.loadUpcomingHearingDays();
    }
  };

  loadUpcomingHearingDays = () => {
    if (!this.props.selectedRegionalOffice) {
      return;
    }

    const regionalOfficeKey = this.props.selectedRegionalOffice.value;
    const requestUrl = `/hearings/schedule/assign/hearing_days?regional_office=${regionalOfficeKey}`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveUpcomingHearingDays(_.keyBy(resp.hearingDays, 'id'));
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadUpcomingHearingDays()
  ]);

  render = () => {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading appeals to be scheduled for hearings...'
      }}>
      <AssignHearings
        onRegionalOfficeChange={this.props.onRegionalOfficeChange}
        selectedRegionalOffice={this.props.selectedRegionalOffice}
        upcomingHearingDays={this.props.upcomingHearingDays}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  selectedRegionalOffice: state.selectedRegionalOffice,
  upcomingHearingDays: state.upcomingHearingDays
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onRegionalOfficeChange,
  onReceiveUpcomingHearingDays
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingsContainer);
