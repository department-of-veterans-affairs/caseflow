import React from 'react';
import PageRoute from 'app/components/PageRoute';

import { PAGE_TITLES } from '../constants';
import { SubstituteAppellantContainer } from './SubstituteAppellantContainer';

const basePath = '/queue/appeals/:appealId/substitute_appellant';

const PageRoutes = [
  <PageRoute path={basePath} title={`${PAGE_TITLES.SUBSTITUTE_APPELLANT} | Caseflow`}>
    <SubstituteAppellantContainer />
  </PageRoute>,
];

const ModalRoutes = [];

export const substituteAppellantRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
