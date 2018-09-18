import React from 'react';
import { connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import { onReceiveRegionalOffices, onRegionalOfficeChange, onReceiveUpcomingHearingDays } from '../actions';
import AssignHearings from '../components/AssignHearings';

class AssignHearingsContainer extends React.PureComponent {

  loadRegionalOffices = () => {
    return ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveRegionalOffices(resp.regionalOffices);
    });
  };

  loadUpcomingHearingDays = () => {
    const requestUrl = `/hearings/hearing_day?regional_office=RO04`;

    return ApiUtil.get(requestUrl).then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));

      this.props.onReceiveUpcomingHearingDays(resp.hearings);
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadRegionalOffices(),
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
        regionalOffices={this.props.regionalOffices}
        onRegionalOfficeChange={this.props.onRegionalOfficeChange}
        selectedRegionalOffice={this.props.selectedRegionalOffice}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

const mapStateToProps = (state) => ({
  regionalOffices: state.regionalOffices,
  selectedRegionalOffice: state.selectedRegionalOffice
});

const mapDispatchToProps = (dispatch) => bindActionCreators({
  onReceiveRegionalOffices,
  onRegionalOfficeChange,
  onReceiveUpcomingHearingDays
}, dispatch);

export default connect(mapStateToProps, mapDispatchToProps)(AssignHearingsContainer);
