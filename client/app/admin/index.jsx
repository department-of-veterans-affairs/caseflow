import React from 'react';
import ReduxBase from '../components/ReduxBase';
// import PropTypes from 'prop-types';
// import { combineReducers } from 'redux';
// import IntakeFrame from './IntakeFrame';
// import { intakeReducer, mapDataToInitialIntake } from './reducers/intake';
import index from './reducers';
import AdminApp from './pages/AdminApp';
import { Router } from 'react-router';
import { createBrowserHistory } from 'history';
// import { BrowserRouter } from 'react-router-dom';

// export const reducer = combineReducers({
//   intake: intakeReducer,
//   featureToggles: featureToggleReducer,
// });

// export const generateInitialState = (props) => ({
//   intake: mapDataToInitialIntake(props),
//   featureToggles: mapDataToFeatureToggle(props),
// });

// class Admin extends React.PureComponent {
//   componentDidMount() {
//     if (window.Raven) {
//       window.Raven.caseflowAppName = 'Admin';
//     }
//   }

//   render() {
//     // const initialState = generateInitialState(this.props);
//     const Router = this.props.router || BrowserRouter;

//     return (
//       <ReduxBase
//         // initialState={initialState}
//         // reducer={reducer}
//         analyticsMiddlewareArgs={['admin']}
//       >
//         <Router basename="/admin" {...this.props.routerTestProps}>
//           {/* <IntakeFrame {...this.props} /> */}
//         </Router>
//         <AdminApp />
//       </ReduxBase>
//     );
//   }
// }
// Admin.propTypes = {
//   router: PropTypes.object,
//   routerTestProps: PropTypes.object,
// };

// export default Admin;

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
