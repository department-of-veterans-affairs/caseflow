import React from 'react';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';

import { Route, Switch, useRouteMatch } from 'react-router';
import { EditCavcRemandView } from './EditCavcRemandView';
import { EditCavcRemandTasks } from './editCavcRemandTasks/editCavcRemandTasksView';
import { EditCavcRemandReview } from './editCavcRemandReview/SubstituteAppellantReview';

export const editCavcRemandContainer = () => {
  const { path } = useRouteMatch();

  return (
    <AppSegment>
      <Switch>
        <Route path={`${path}`} title = "Edit Cavc Remand | Caseflow">
          <EditCavcRemandView />
        </Route>

        <Route path={`${path}/tasks`} title = "Edit Cavc Remand | Caseflow">
          <EditCavcRemandTasks />
        </Route>

        <Route path={`${path}/review`} title = "Edit Cavc Remand | Caseflow">
          <EditCavcRemandReview />
        </Route>

      </Switch>
    </AppSegment>

  );
};
