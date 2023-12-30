import React from 'react';
import PageRoute from 'app/components/PageRoute';

import { EditCavcRemandContainer } from './editCavcRemandContainer';
import { replaceSpecialCharacters } from '../utils';

const basePath = '/queue/appeals/:appealId/edit_cavc_remand';

const PageRoutes = [
  <PageRoute path={basePath} title="Edit Cavc Remand | Caseflow" key={replaceSpecialCharacters(basePath)} >
    <EditCavcRemandContainer />
  </PageRoute>,
];

const ModalRoutes = [];

export const editCavcRemandRoutes = {
  page: PageRoutes,
  modal: ModalRoutes,
};
