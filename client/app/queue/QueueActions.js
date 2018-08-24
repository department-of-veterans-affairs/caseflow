// @flow
import { associateTasksWithAppeals, prepareLegacyTasksForStore, extractAppealsAndAmaTasks } from './utils';
import { ACTIONS } from './constants';
import { hideErrorMessage } from './uiReducer/uiActions';
import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';
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

export const setAppealDocCount = (appealId: string, docCount: number) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCount
  }
});

export const setCaseReviewActionType = (type: string) => ({
  type: ACTIONS.SET_REVIEW_ACTION_TYPE,
  payload: {
    type
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

export const fetchTasksAndAppealsOfAttorney = (attorneyId: string) => (dispatch: Dispatch) => {
  const requestOptions = {
    timeout: true
  };

  dispatch(requestTasksAndAppealsOfAttorney(attorneyId));

  return ApiUtil.get(`/queue/${attorneyId}`, requestOptions).then(
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

export const initialAssignTasksToUser =
  ({ tasks, assigneeId, previousAssigneeId }:
     { tasks: Array<Task>, assigneeId: string, previousAssigneeId: string}) =>
    (dispatch: Dispatch) =>
      Promise.all(tasks.map((oldTask) => {
        return ApiUtil.post(
          '/legacy_tasks',
          { data: { tasks: { assigned_to_id: assigneeId,
            type: 'JudgeCaseAssignmentToAttorney',
            appeal_id: oldTask.appealId } } }).
          then((resp) => resp.body).
          then(
            (resp) => {
              const { task: { data: task } } = resp;

              dispatch(onReceiveTasks({ amaTasks: {},
                tasks: prepareLegacyTasksForStore([task]) }));
              dispatch(setSelectionOfTaskOfUser({ userId: previousAssigneeId,
                taskId: task.id,
                selected: false }));
            });
      }));

export const reassignTasksToUser =
  ({ tasks, assigneeId, previousAssigneeId }:
     { tasks: Array<Task>, assigneeId: string, previousAssigneeId: string}) =>
    (dispatch: Dispatch) =>
      Promise.all(tasks.map((oldTask) => {
        return ApiUtil.patch(
          `/legacy_tasks/${oldTask.taskId}`,
          { data: { tasks: { assigned_to_id: assigneeId } } }).
          then((resp) => resp.body).
          then(
            (resp) => {
              const { task: { data: task } } = resp;

              dispatch(onReceiveTasks({ amaTasks: {},
                tasks: prepareLegacyTasksForStore([task]) }));
              dispatch(setSelectionOfTaskOfUser({ userId: previousAssigneeId,
                taskId: task.id,
                selected: false }));
            });
      }));

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

export const setTaskAssignment = (externalAppealId: string, cssId: string, pgId: number) => ({
  type: ACTIONS.SET_TASK_ASSIGNMENT,
  payload: {
    externalAppealId,
    cssId,
    pgId
  }
});

export const setTaskAttrs = (externalAppealId: string, attributes: Object) => ({
  type: ACTIONS.SET_TASK_ATTRS,
  payload: {
    externalAppealId,
    attributes
  }
});
