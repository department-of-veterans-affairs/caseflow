import React from 'react';
import { BrowserRouter, Switch } from 'react-router-dom';
// import PageRoute from '../components/PageRoute';
import PageRoute from '../../components/PageRoute';
// import ReduxBase from '../components/ReduxBase';
import reducers from '../reducers/index';
// export const Admin = ({
//   sys_admin,
//   errors,
//   showDivider,
//   formFieldsOnly,
//   update,
//   actionType
// }) => {
// export const AdminApp = () => {
//   return (
//     <h1>System Admin UI</h1>
//   );
// };

export default class AdminApp extends React.PureComponent {
  render = () => <BrowserRouter basename="/admin">
    <div>
      <Switch>
        <PageRoute
          exact
          path="/admin"
          title="admin"
          render={this.admin}
        />
      </Switch>
      <h1>System Admin UI</h1>
    </div>
  </BrowserRouter>
}

export const reducer = reducers;

AdminApp.propTypes = {

};
