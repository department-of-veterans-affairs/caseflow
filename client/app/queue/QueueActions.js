/* eslint-disable max-lines */
// @flow
import { associateTasksWithAppeals,
  prepareAllTasksForStore,
  extractAppealsAndAmaTasks,
  prepareTasksForStore } from './utils';
import { ACTIONS } from './constants';
import { hideErrorMessage, showErrorMessage, showSuccessMessage } from './uiReducer/uiActions';
import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';
import pluralize from 'pluralize';
import type { Dispatch } from './types/state';
import type {
  Task,
  Tasks,
  BasicAppeals,
  AppealDetails,
  User
} from './types/models';

export const onReceiveQueue = (
  { tasks, amaTasks, appeals }:
  { tasks: Tasks, amaTasks: Tasks, appeals: BasicAppeals }
) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    amaTasks,
    appeals
  }
});

export const onReceiveAppealDetails = (
  { appeals, appealDetails }: { appeals: BasicAppeals, appealDetails: AppealDetails }
) => ({
  type: ACTIONS.RECEIVE_APPEAL_DETAILS,
  payload: {
    appeals,
    appealDetails
  }
});

export const onReceiveTasks = (
  { tasks, amaTasks }: { tasks: Tasks, amaTasks: Tasks }
) => ({
  type: ACTIONS.RECEIVE_TASKS,
  payload: {
    tasks,
    amaTasks
  }
});

export const onReceiveAmaTasks = (amaTasks: Array<Object>) => ({
  type: ACTIONS.RECEIVE_AMA_TASKS,
  payload: {
    amaTasks: prepareTasksForStore(amaTasks)
  }
});

export const fetchJudges = () => (dispatch: Dispatch) => {
  ApiUtil.get('/users?role=Judge').then((response) => {
    const resp = JSON.parse(response.text);
    const judges = _.keyBy(resp.judges, 'id');

    dispatch({
      type: ACTIONS.RECEIVE_JUDGE_DETAILS,
      payload: {
        judges
      }
    });
  });
};

export const receiveNewDocuments = ({ appealId, newDocuments }: { appealId: string, newDocuments: Array<Object> }) => ({
  type: ACTIONS.RECEIVE_NEW_FILES,
  payload: {
    appealId,
    newDocuments
  }
});

export const getNewDocuments = (appealId: string) => (dispatch: Dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_LOADING_DOCUMENTS,
    payload: {
      appealId
    }
  });
  ApiUtil.get(`/appeals/${appealId}/new_documents`).then((response) => {
    const resp = JSON.parse(response.text);

    dispatch(receiveNewDocuments({
      appealId,
      newDocuments: resp.new_documents
    }));
  }, (error) => {
    dispatch({
      type: ACTIONS.ERROR_ON_RECEIVE_NEW_FILES,
      payload: {
        appealId,
        error
      }
    });
  });
};

export const getAppealValue = (appealId: string, endpoint: string, name: string) => (dispatch: Dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_LOADING_APPEAL_VALUE,
    payload: {
      appealId,
      name
    }
  });
  ApiUtil.get(`/appeals/${appealId}/${endpoint}`).then((resp) => {
    const response = JSON.parse(resp.text);

    dispatch({
      type: ACTIONS.RECEIVE_APPEAL_VALUE,
      payload: {
        appealId,
        name,
        response
      }
    });
  }, (error) => {
    dispatch({
      type: ACTIONS.ERROR_ON_RECEIVE_APPEAL_VALUE,
      payload: {
        appealId,
        name,
        error
      }
    });
  });
};

export const setAppealDocCount = (appealId: string, docCount: number) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCount
  }
});

export const setDecisionOptions = (opts: Object) => (dispatch: Dispatch) => {
  dispatch(hideErrorMessage());
  dispatch({
    type: ACTIONS.SET_DECISION_OPTIONS,
    payload: {
      opts
    }
  });
};

export const resetDecisionOptions = () => ({
  type: ACTIONS.RESET_DECISION_OPTIONS
});

const editAppeal = (appealId, attributes) => ({
  type: ACTIONS.EDIT_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const deleteAppeal = (appealId: string) => ({
  type: ACTIONS.DELETE_APPEAL,
  payload: {
    appealId
  }
});

export const editStagedAppeal = (appealId: string, attributes: Object) => ({
  type: ACTIONS.EDIT_STAGED_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const checkoutStagedAppeal = (appealId: string) => ({
  type: ACTIONS.CHECKOUT_STAGED_APPEAL,
  payload: {
    appealId
  }
});

export const stageAppeal = (appealId: string) => (dispatch: Dispatch) => {
  dispatch(checkoutStagedAppeal(appealId));

  dispatch({
    type: ACTIONS.STAGE_APPEAL,
    payload: {
      appealId
    }
  });
};

export const updateEditingAppealIssue = (attributes: Object) => ({
  type: ACTIONS.UPDATE_EDITING_APPEAL_ISSUE,
  payload: {
    attributes
  }
});

export const startEditingAppealIssue =
  (appealId: string, issueId: string, attributes: Object) => (dispatch: Dispatch) => {
    dispatch({
      type: ACTIONS.START_EDITING_APPEAL_ISSUE,
      payload: {
        appealId,
        issueId
      }
    });

    if (attributes) {
      dispatch(updateEditingAppealIssue(attributes));
    }
  };

export const deleteEditingAppealIssue =
  (appealId: string, issueId: string, attributes: Object) => (dispatch: Dispatch) => {
    dispatch({
      type: ACTIONS.DELETE_EDITING_APPEAL_ISSUE,
      payload: {
        appealId,
        issueId
      }
    });
    dispatch(editAppeal(appealId, attributes));
  };

export const cancelEditingAppealIssue = () => ({
  type: ACTIONS.CANCEL_EDITING_APPEAL_ISSUE
});

export const saveEditedAppealIssue = (appealId: string, attributes: { issues: Object }) => (dispatch: Dispatch) => {
  dispatch({
    type: ACTIONS.SAVE_EDITED_APPEAL_ISSUE,
    payload: {
      appealId
    }
  });

  if (attributes) {
    dispatch(editStagedAppeal(appealId, attributes));
    dispatch(editAppeal(appealId, attributes));
  }
};

export const setAttorneysOfJudge = (attorneys: Array<User>) => ({
  type: ACTIONS.SET_ATTORNEYS_OF_JUDGE,
  payload: {
    attorneys
  }
});

const receiveTasksAndAppealsOfAttorney = ({ attorneyId, tasks, appeals }) => ({
  type: ACTIONS.SET_TASKS_AND_APPEALS_OF_ATTORNEY,
  payload: {
    attorneyId,
    tasks,
    appeals
  }
});

const requestTasksAndAppealsOfAttorney = (attorneyId) => ({
  type: ACTIONS.REQUEST_TASKS_AND_APPEALS_OF_ATTORNEY,
  payload: {
    attorneyId
  }
});

const errorTasksAndAppealsOfAttorney = ({ attorneyId, error }) => ({
  type: ACTIONS.ERROR_TASKS_AND_APPEALS_OF_ATTORNEY,
  payload: {
    attorneyId,
    error
  }
});

export const fetchTasksAndAppealsOfAttorney = (attorneyId: string, params: Object) => (dispatch: Dispatch) => {
  const requestOptions = {
    timeout: true
  };

  dispatch(requestTasksAndAppealsOfAttorney(attorneyId));

  const pairs = Object.keys(params).map((key) => [key, params[key]].join('='));
  const queryString = `?${pairs.join('&')}`;

  return ApiUtil.get(`/queue/${attorneyId}${queryString}`, requestOptions).then(
    (resp) => dispatch(
      receiveTasksAndAppealsOfAttorney(
        { attorneyId,
          ...associateTasksWithAppeals(JSON.parse(resp.text)) })),
    (error) => dispatch(errorTasksAndAppealsOfAttorney({ attorneyId,
      error }))
  );
};

export const setSelectionOfTaskOfUser =
  ({ userId, taskId, selected }: {userId: string, taskId: string, selected: boolean}) => ({
    type: ACTIONS.SET_SELECTION_OF_TASK_OF_USER,
    payload: {
      userId,
      taskId,
      selected
    }
  });

export const initialAssignTasksToUser = ({
  tasks, assigneeId, previousAssigneeId
}: {
  tasks: Array<Task>, assigneeId: string, previousAssigneeId: string
}) => (dispatch: Dispatch) => Promise.all(tasks.map((oldTask) => {
  let params, url;

  if (oldTask.appealType === 'Appeal') {
    url = '/tasks?role=Judge';
    params = {
      data: {
        tasks: [{
          type: 'AttorneyTask',
          external_id: oldTask.externalAppealId,
          parent_id: oldTask.taskId,
          assigned_to_id: assigneeId
        }]
      }
    };
  } else {
    url = '/legacy_tasks';
    params = {
      data: {
        tasks: {
          assigned_to_id: assigneeId,
          type: 'JudgeCaseAssignmentToAttorney',
          appeal_id: oldTask.appealId
        }
      }
    };
  }

  return ApiUtil.post(url, params).
    then((resp) => resp.body).
    then((resp) => {
      if (oldTask.appealType === 'Appeal') {
        const amaTasks = resp.tasks.data;

        dispatch(onReceiveAmaTasks(
          amaTasks
        ));
      } else {
        const task = resp.task.data;
        const allTasks = prepareAllTasksForStore([task]);

        dispatch(onReceiveTasks({
          tasks: allTasks.tasks,
          amaTasks: allTasks.amaTasks
        }));
      }

      dispatch(setSelectionOfTaskOfUser({
        userId: previousAssigneeId,
        taskId: oldTask.uniqueId,
        selected: false
      }));
    });
}));

export const reassignTasksToUser = ({
  tasks, assigneeId, previousAssigneeId
}: {
  tasks: Array<Task>, assigneeId: string, previousAssigneeId: string
}) => (dispatch: Dispatch) => Promise.all(tasks.map((oldTask) => {
  let params, url;

  if (oldTask.appealType === 'Appeal') {
    url = `/tasks/${oldTask.taskId}?role=Judge`;
    params = {
      data: {
        task: {
          type: 'AttorneyTask',
          assigned_to_id: assigneeId
        }
      }
    };
  } else {
    url = `/legacy_tasks/${oldTask.taskId}`;
    params = {
      data: {
        tasks: {
          assigned_to_id: assigneeId,
          type: 'JudgeCaseAssignmentToAttorney',
          appeal_id: oldTask.appealId
        }
      }
    };
  }

  return ApiUtil.patch(url, params).
    then((resp) => resp.body).
    then((resp) => {
      if (oldTask.appealType === 'Appeal') {
        const amaTasks = resp.tasks.data;

        dispatch(onReceiveAmaTasks(
          amaTasks
        ));
      } else {
        const task = resp.task.data;
        const allTasks = prepareAllTasksForStore([task]);

        dispatch(onReceiveTasks({
          tasks: allTasks.tasks,
          amaTasks: allTasks.amaTasks
        }));
      }

      dispatch(setSelectionOfTaskOfUser({
        userId: previousAssigneeId,
        taskId: oldTask.uniqueId,
        selected: false
      }));
    });
}));

const refreshLegacyTasks = (dispatch, userId) =>
  ApiUtil.get(`/queue/${userId}`, { timeout: { response: 5 * 60 * 1000 } }).
    then((response) =>
      dispatch(onReceiveQueue({
        amaTasks: {},
        ...associateTasksWithAppeals(JSON.parse(response.text))
      }))
    );

const setPendingDistribution = (distribution) => ({
  type: ACTIONS.SET_PENDING_DISTRIBUTION,
  payload: {
    distribution
  }
});

const distributionError = (dispatch, userId, error) => {
  const firstError = error.response.body.errors[0];

  dispatch(showErrorMessage(firstError));

  if (firstError.error === 'unassigned_cases') {
    dispatch(setPendingDistribution({ status: 'completed' }));
    refreshLegacyTasks(dispatch, userId).then(() => dispatch(setPendingDistribution(null)));
  } else {
    dispatch(setPendingDistribution(null));
  }
};

const receiveDistribution = (dispatch, userId, response) => {
  const distribution = response.body.distribution;

  dispatch(setPendingDistribution(distribution));

  if (distribution.status === 'completed') {
    const caseN = distribution.distributed_cases_count;

    dispatch(showSuccessMessage({
      title: 'Distribution Complete',
      detail: `${caseN} new ${pluralize('case', caseN)} have been distributed from the docket.`
    }));

    refreshLegacyTasks(dispatch, userId).then(() => dispatch(setPendingDistribution(null)));
  } else {
    // Poll until the distribution completes or errors out.
    ApiUtil.get(`/distributions/${distribution.id}`).
      then((resp) => receiveDistribution(dispatch, userId, resp)).
      catch((error) => distributionError(dispatch, userId, error));
  }
};

export const requestDistribution = (userId: string) => (dispatch: Dispatch) => {
  dispatch(setPendingDistribution({ status: 'pending' }));

  ApiUtil.get('/distributions/new').
    then((response) => receiveDistribution(dispatch, userId, response)).
    catch((error) => distributionError(dispatch, userId, error));
};

const receiveAllAttorneys = (attorneys) => ({
  type: ACTIONS.RECEIVE_ALL_ATTORNEYS,
  payload: {
    attorneys
  }
});

const errorAllAttorneys = (error) => ({
  type: ACTIONS.ERROR_LOADING_ATTORNEYS,
  payload: {
    error
  }
});

export const fetchAllAttorneys = () => (dispatch: Dispatch) =>
  ApiUtil.get('/users?role=Attorney').
    then((resp) => dispatch(receiveAllAttorneys(resp.body.attorneys))).
    catch((error) => Promise.reject(dispatch(errorAllAttorneys(error))));

export const fetchAmaTasksOfUser = (userId: number, userRole: string) => (dispatch: Dispatch) =>
  ApiUtil.get(`/tasks?user_id=${userId}&role=${userRole}`).
    then((resp) => dispatch(onReceiveQueue(extractAppealsAndAmaTasks(resp.body.tasks.data))));

export const setAppealAttrs = (appealId: string, attributes: Object) => ({
  type: ACTIONS.SET_APPEAL_ATTRS,
  payload: {
    appealId,
    attributes
  }
});

export const setSpecialIssues = (specialIssues: Object) => ({
  type: ACTIONS.SET_SPECIAL_ISSUE,
  payload: {
    specialIssues
  }
});

export const setAppealAod = (externalAppealId: string) => ({
  type: ACTIONS.SET_APPEAL_AOD,
  payload: {
    externalAppealId
  }
});
