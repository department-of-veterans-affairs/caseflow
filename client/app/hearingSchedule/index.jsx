import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import reducers, { initialState } from './reducers';
import HearingsApp from './HearingsApp';

const Hearings = (props) => <ReduxBase store={initialState} reducer={reducers}>
  <HearingsApp {...props} />
</ReduxBase>;

export default Hearings;
