// Runtime Dependencies
import 'core-js/stable';
import 'regenerator-runtime/runtime';

// Style dependencies
import 'app/styles/app.scss';
import 'pdfjs-dist/web/pdf_viewer.css';

// External Dependencies
import React, { Suspense } from 'react';
import ReactOnRails from 'react-on-rails';
import { createRoot } from 'react-dom/client';
import { forOwn } from 'lodash';
import { BrowserRouter, Switch } from 'react-router-dom';

// Internal Dependencies
import { storeMetrics } from './util/Metrics';

// Redux Store Dependencies
import ReduxBase from 'app/components/ReduxBase';
import rootReducer from './reader/store/root';
// Shared Component Dependencies
import { ErrorBoundary } from './components/ErrorBoundary';
import Loadable from './components/Loadable';
import { LOGO_COLORS } from 'app/constants/AppConstants';

// List of container components we render directly in  Rails .erb files
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
import UnderConstruction from 'app/containers/UnderConstruction';
import Login from 'app/login';
import TestApp from 'app/test/TestApp';
import TestUsers from 'app/test/TestUsers';
import TestData from 'app/test/TestData';
import LoadTest from 'app/test/loadTest/LoadTest';
import PerformanceDegradationBanner from 'app/components/PerformanceDegradationBanner';
import EstablishClaimAdmin from 'app/establishClaimAdmin';
import Queue from 'app/queue/index';
import IntakeManager from 'app/intakeManager';
import IntakeEdit from 'app/intakeEdit';
import NonComp from 'app/nonComp';
import AsyncableJobs from 'app/asyncableJobs';
import Inbox from 'app/inbox';
import Explain from 'app/explain';
import MPISearch from 'app/mpi/MPISearch';
import Admin from 'app/admin';
import CaseDistribution from 'app/caseDistribution';
import CaseDistributionTest from 'app/caseDistribution/test';
import TestSeeds from 'app/testSeeds';
import uuid from 'uuid';
import TestCorrespondence from 'app/test/TestCorrespondence';

const COMPONENTS = {
  // New Version 2.0 Root Component
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
  TestCorrespondence,
  TestApp,
  TestUsers,
  TestData,
  LoadTest,
  Error403,
  Error404,
  Error500,
  OutOfService,
  Unauthorized,
  Feedback,
  UnderConstruction,
  Hearings,
  PerformanceDegradationBanner,
  Help,
  Queue,
  IntakeManager,
  IntakeEdit,
  NonComp,
  AsyncableJobs,
  Inbox,
  Explain,
  MPISearch,
  Admin,
  CaseDistribution,
  CaseDistributionTest,
  TestSeeds
};

const componentWrapper = (component) => (props, railsContext, domNodeId) => {
  window.onerror = (event, source, lineno, colno, error) => {
    if (props.featureToggles?.metricsBrowserError) {
      const id = uuid.v4();
      const data = {
        event,
        source,
        lineno,
        colno,
        error
      };
      const t0 = performance.now();
      const start = Date.now();
      const t1 = performance.now();
      const end = Date.now();
      const duration = t1 - t0;

      storeMetrics(
        id,
        data,
        { message: event,
          type: 'error',
          product: 'caseflow',
          start,
          end,
          duration }
      );
    }

    return true;
  };

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
    const container = document.getElementById(domNodeId);
    const root = createRoot(container);

    root.render(element);
  };

  renderApp(component);

  if (module.hot) {
    module.hot.accept(
      [
        './containers/BaseContainer',
        './containers/EstablishClaimPage/index',
        './login/index',
        './test/TestCorrespondence',
        './test/TestUsers',
        './test/TestData',
        './certification/Certification',
        './manageEstablishClaim/ManageEstablishClaim',
        './hearings/index',
        './establishClaimAdmin/index',
        './queue/index',
        './intakeManager/index',
        './intakeEdit/index',
        './nonComp/index',
        './explain/index',
        './mpi/MPISearch',
        './admin/index',
        './caseDistribution/index',
        './testSeeds/index'
      ],
      () => renderApp(component)
    );
  }
};

forOwn(COMPONENTS, (component, name) =>
  ReactOnRails.register({ [name]: componentWrapper(component) })
);
