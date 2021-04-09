import React from 'react';
import { Redirect, Route, Switch } from 'react-router';
import PageRoute from 'app/components/PageRoute';

import { GrantedSubstitutionBasicsView } from './GrantedSubstitutionBasicsView';

const basePath = '/queue/appeals/:appealId/substitute_appellant';

const PageRoutes = [
  <PageRoute path={basePath} title="Substitute Appellant | Caseflow">
    <Switch>
      <Redirect exact from={[basePath, `${basePath}/`]} to={`${basePath}/basics`} />
      <PageRoute
        path={`${basePath}/basics`}
        title="Substitute Appellant | Caseflow"
      >
        <GrantedSubstitutionBasicsView />
      </PageRoute>
    </Switch>
  </PageRoute>,
];

const ModalRoutes = [];

export const grantedSubstitutionRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
