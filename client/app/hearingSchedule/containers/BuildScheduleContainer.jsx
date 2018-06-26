import React from 'react';
import BuildSchedule from '../components/BuildSchedule';

export class BuildScheduleContainer extends React.Component {

  render() {
    return <BuildSchedule
      pastUploads={[
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'Judge',
          createdAt: '07/03/2018',
          user: 'Justin Madigan',
          fileName: 'fake file name'
        },
        {
          startDate: '10/01/2018',
          endDate: '03/31/2019',
          type: 'RO/CO',
          createdAt: '07/03/2018',
          user: 'Justin Madigan',
          fileName: 'fake file name'
        }
      ]}
    />;
  }
}

export default BuildScheduleContainer;
