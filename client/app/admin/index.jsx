import React from 'react';
import ReduxBase from '../components/ReduxBase';
import index from './reducers';
import AdminApp from './pages/AdminApp';
import { Router } from 'react-router';
import { createBrowserHistory } from 'history';

const history = createBrowserHistory();

const Admin = (props) => {
  return (
    <ReduxBase
      reducer={index}
    >
      <Router history={history}>
        <AdminApp {...props} />
      </Router>
    </ReduxBase>
  );
};

export default Admin;
