// External Dependencies
import React from 'react';

// Local Dependencies
import ReduxBase from 'app/components/ReduxBase';
import rootReducer from 'app/reader/reducers';
import { Router } from 'app/2.0/router';

export const Root = (props) => {
  return (
    <ReduxBase reducer={rootReducer}>
      <Router {...props} />
    </ReduxBase>
  );
};
