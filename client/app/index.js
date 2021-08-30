// Runtime Dependencies
import 'core-js/stable';
import 'regenerator-runtime/runtime';

// Style dependencies
import 'app/styles/app.scss';
import 'pdfjs-dist/web/pdf_viewer.css';

// External Dependencies
import React, { Suspense } from 'react';
import ReactOnRails from 'react-on-rails';
import { render } from 'react-dom';
import { forOwn } from 'lodash';
import { BrowserRouter, Switch } from 'react-router-dom';

// Redux Store Dependencies
import ReduxBase from 'app/components/ReduxBase';
import rootReducer from 'store/root';

// Shared Component Dependencies
import { ErrorBoundary } from 'components/shared/ErrorBoundary';
import Loadable from 'components/shared/Loadable';
import { LOGO_COLORS } from 'app/constants/AppConstants';

// List of container components we render directly in  Rails .erb files
import Router from 'app/2.0/router';
import BaseContainer from 'app/containers/BaseContainer';
import Certification from 'app/certification/Certification';

// Dispatch
import EstablishClaimPage from 'app/containers/EstablishClaimPage';
import ManageEstablishClaim from 'app/manageEstablishClaim/index';
import CaseWorker from 'app/containers/CaseWorker/CaseWorkerIndex';

import Hearings from 'app/hearings/index';
import Help from 'app/help/index';
import Error500 from 'app/errors/Error500';
import Error404 from 'app/errors/Error404';
import Error403 from 'app/errors/Error403';
import Unauthorized from 'app/containers/Unauthorized';
import OutOfService from 'app/containers/OutOfService';
import Feedback from 'app/containers/Feedback';
import StatsContainer from 'app/containers/stats/StatsContainer';
import Login from 'app/login';
import TestUsers from 'app/test/TestUsers';
import TestData from 'app/test/TestData';
import PerformanceDegradationBanner from 'app/components/PerformanceDegradationBanner';
import EstablishClaimAdmin from 'app/establishClaimAdmin';
import Queue from 'app/queue/index';
import IntakeManager from 'app/intakeManager';
import IntakeEdit from 'app/intakeEdit';
import NonComp from 'app/nonComp';
import AsyncableJobs from 'app/asyncableJobs';
import Inbox from 'app/inbox';
import Explain from 'app/explain';

const COMPONENTS = {
  // New Version 2.0 Root Component
  Router,
  BaseContainer,
  Certification,
  // New SPA wrapper for multiple admin pages
  EstablishClaimAdmin,
  // This is the older admin page that should eventually get merged into
  // the above EstablishClaimAdmin
  ManageEstablishClaim,
  EstablishClaimPage,
  CaseWorker,
  Login,
  TestUsers,
  TestData,
  Error403,
  Error404,
  Error500,
  OutOfService,
  Unauthorized,
  Feedback,
  StatsContainer,
  Hearings,
  PerformanceDegradationBanner,
  Help,
  Queue,
  IntakeManager,
  IntakeEdit,
  NonComp,
  AsyncableJobs,
  Inbox,
  Explain
};

const componentWrapper = (component) => (props, railsContext, domNodeId) => {
  /* eslint-disable */
  const wrapComponent = (Component) => (
    <ErrorBoundary>
      {props.featureToggles?.interfaceVersion2 ? (
        <ReduxBase reducer={rootReducer}>
          <BrowserRouter>
            <Switch>
              <Loadable spinnerColor={LOGO_COLORS[props.appName.toUpperCase()].ACCENT}>
                <Component {...props} />
              </Loadable>
            </Switch>
          </BrowserRouter>
        </ReduxBase>
      ) : (
        <Suspense fallback={<div />}>
          <Component {...props} />
        </Suspense>
      )}
    </ErrorBoundary>
  );
  /* eslint-enable */

  const renderApp = (Component) => {
    const element = wrapComponent(Component);

    render(element, document.getElementById(domNodeId));
  };

  renderApp(component);

  if (module.hot) {
    module.hot.accept(
      [
        './containers/BaseContainer',
        './containers/EstablishClaimPage/index',
        './login/index',
        './test/TestUsers',
        './test/TestData',
        './containers/stats/StatsContainer',
        './certification/Certification',
        './manageEstablishClaim/ManageEstablishClaim',
        './hearings/index',
        './establishClaimAdmin/index',
        './queue/index',
        './intakeManager/index',
        './intakeEdit/index',
        './nonComp/index',
        './2.0/router',
        './explain/index'
      ],
      () => renderApp(component)
    );
  }
};

forOwn(COMPONENTS, (component, name) =>
  ReactOnRails.register({ [name]: componentWrapper(component) })
);
