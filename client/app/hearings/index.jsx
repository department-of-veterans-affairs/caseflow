import React from 'react';
import ReduxBase from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/ReduxBase';
import reducers from './reducers/index';
import HearingsApp from './HearingsApp';

const Hearings = (props) => <ReduxBase store={{}} reducer={reducers}>
  <HearingsApp {...props} />
</ReduxBase>;

export default Hearings;
