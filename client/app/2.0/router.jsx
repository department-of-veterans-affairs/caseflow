// External Dependencies
import React from 'react';
import { BrowserRouter, Switch } from 'react-router-dom';

// Internal Dependencies
import Loadable from 'app/2.0/components/shared/Loadable';

// Lazy Load Routes
const ReaderRoutes = React.lazy(() => import('app/2.0/routes/Reader'));

export const Router = (props) => {
  return (
    <BrowserRouter basename="/reader/appeal" >
      <Switch>
        <Loadable>
          <ReaderRoutes {...props} />
        </Loadable>
      </Switch>
    </BrowserRouter>
  );
};
