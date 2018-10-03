import React from 'react';
import DailyDocket from '../components/DailyDocket';
import { LOGO_COLORS } from '../../constants/AppConstants';
import LoadingDataDisplay from '../../components/LoadingDataDisplay';

export default class DailyDocketContainer extends React.Component {

  createHearingPromise = () => Promise.all([true]);

  render() {
    const loadingDataDisplay = <LoadingDataDisplay
      createLoadPromise={this.createHearingPromise}
      loadingComponentProps={{
        spinnerColor: LOGO_COLORS.HEARING_SCHEDULE.ACCENT,
        message: 'Loading the daily docket...'
      }}
      failStatusMessageProps={{
        title: 'Unable to load the daily docket.'
      }}>
      <DailyDocket
        vlj="Kim Anderson"
        coordinator="James Jean"
        hearingType="Central Office"
        hearingDate="2018-10-13"
        hearings={{
          123: {
            issueCount: 4,
            appellantName: 'Alexander Richard',
            vbmsId: 123456789,
            appellantAddress: '3127 Dellar Rd',
            appellantCity: 'Houston',
            appellantState: 'TX',
            appellantZipCode: '77030',
            hearingLocation: 'Houston, TX',
            hearingTime: '9:30AM EST, 8:30AM CST',
            representative: 'Military Order of the Purple Heart',
            representativeName: "Patrick O'Sullivan",
            disposition: null,
            hearingDate: '2018-10-13'
          } }}
      />
    </LoadingDataDisplay>;

    return <div>{loadingDataDisplay}</div>;
  }
}
