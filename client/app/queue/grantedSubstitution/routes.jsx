import React from 'react';
import { Switch } from 'react-router';
import PageRoute from 'app/components/PageRoute';

import { GrantedSubstitutionBasicsView } from './GrantedSubstitutionBasicsView';

const PageRoutes = [
  <PageRoute
    path="/queue/appeals/:appealId/substitute_appellant"
    title="Substitute Appellant | Caseflow"
  >
    <Switch>
      <PageRoute
        path="/queue/appeals/:appealId/substitute_appellant/basics"
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
