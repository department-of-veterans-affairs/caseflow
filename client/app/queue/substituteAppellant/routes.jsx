import React from 'react';
import PageRoute from 'app/components/PageRoute';

import { SubstituteAppellantContainer } from './SubstituteAppellantContainer';

const basePath = '/queue/appeals/:appealId/substitute_appellant';

const PageRoutes = [
  <PageRoute path={basePath} title="Substitute Appellant | Caseflow">
    <SubstituteAppellantContainer />
  </PageRoute>,
];

const ModalRoutes = [];

export const substituteAppellantRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
