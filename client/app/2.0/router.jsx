// External Dependencies
import React from 'react';
import { BrowserRouter, Switch } from 'react-router-dom';

// Lazy Load Routes
const ReaderRoutes = React.lazy(() => import('app/2.0/routes/Reader'));

const Router = (props) => {
  return (
    <BrowserRouter basename="/reader/appeal" >
      <Switch>
        <ReaderRoutes {...props} />
      </Switch>
    </BrowserRouter>
  );
};

export default Router;
