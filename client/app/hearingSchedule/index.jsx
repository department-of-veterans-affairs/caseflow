import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import reducers, { initialState } from './reducers';

import HearingScheduleApp from './HearingScheduleApp';

const HearingSchedule = (props) => <ReduxBase store={initialState} reducer={reducers}>
  <HearingScheduleApp {...props} />
</ReduxBase>;

export default HearingSchedule;
