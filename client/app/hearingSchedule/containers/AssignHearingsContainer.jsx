import React from 'react';
import { LOGO_COLORS } from '../../constants/AppConstants';
import ApiUtil from '../../util/ApiUtil';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';
import AssignHearings from '../components/AssignHearings';

class AssignHearingsContainer extends React.PureComponent {

  loadRegionalOffices = () => {
    return ApiUtil.get('/regional_offices.json').then((response) => {
      const resp = ApiUtil.convertToCamelCase(JSON.parse(response.text));
      console.log(resp)
    });
  };

  createLoadPromise = () => Promise.all([
    this.loadRegionalOffices()
  ]);

  render = () => {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createLoadPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading appeals to be scheduled for hearings...'
      }}>
      <AssignHearings
        regionalOffices={["Boston, MA", "Philadelphia, PA"]}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}

export default AssignHearingsContainer;
