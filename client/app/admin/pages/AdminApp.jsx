import React from 'react';
import { BrowserRouter } from 'react-router-dom';
// import ReduxBase from '../components/ReduxBase';
// import reducers from '../reducers/index';
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
    <h1>System Admin UI</h1>
  </BrowserRouter>
}

AdminApp.propTypes = {

};
