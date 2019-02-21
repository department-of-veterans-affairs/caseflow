/* eslint-disable max-lines */
import { associateTasksWithAppeals,
  prepareAllTasksForStore,
  extractAppealsAndAmaTasks,
  prepareMostRecentlyHeldHearingForStore,
  prepareTasksForStore } from './utils';
import { ACTIONS } from './constants';
import { hideErrorMessage, showErrorMessage, showSuccessMessage } from './uiReducer/uiActions';
import ApiUtil from '../util/ApiUtil';
import _ from 'lodash';
import pluralize from 'pluralize';
import moment from 'moment';

export const onReceiveQueue = (
  { tasks, amaTasks, appeals }
) => ({
  type: ACTIONS.RECEIVE_QUEUE_DETAILS,
  payload: {
    tasks,
    amaTasks,
    appeals
  }
});

export const onReceiveAppealDetails = (
  { appeals, appealDetails }
) => ({
  type: ACTIONS.RECEIVE_APPEAL_DETAILS,
  payload: {
    appeals,
    appealDetails
  }
});

export const onReceiveClaimReviewDetails = (
  { claimReviews }
) => ({
  type: ACTIONS.RECEIVE_CLAIM_REVIEW_DETAILS,
  payload: {
    claimReviews
  }
});

export const onReceiveTasks = (
  { tasks, amaTasks }
) => ({
  type: ACTIONS.RECEIVE_TASKS,
  payload: {
    tasks,
    amaTasks
  }
});

export const onReceiveAmaTasks = (amaTasks) => ({
  type: ACTIONS.RECEIVE_AMA_TASKS,
  payload: {
    amaTasks: prepareTasksForStore(amaTasks)
  }
});

export const fetchJudges = () => (dispatch) => {
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

export const receiveNewDocuments = ({ appealId, newDocuments }) => ({
  type: ACTIONS.RECEIVE_NEW_FILES,
  payload: {
    appealId,
    newDocuments
  }
});

export const getNewDocuments = (appealId, cached, onHoldDate) => (dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_LOADING_DOCUMENTS,
    payload: {
      appealId
    }
  });
  const requestOptions = {
    timeout: { response: 5 * 60 * 1000 }
  };

  let query = cached ? 'cached' : '';

  if (onHoldDate) {
    const timestamp = moment(onHoldDate).unix();

    query += query ? `&placed_on_hold_date=${timestamp}` : `placed_on_hold_date=${timestamp}`;
  }

  ApiUtil.get(`/appeals/${appealId}/new_documents${query ? `?${query}` : ''}`, requestOptions).then((response) => {
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

export const loadAppealDocCount = (appealId) => (dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_DOC_COUNT_REQUEST,
    payload: {
      appealId
    }
  });
};

export const getAppealValue = (appealId, endpoint, name) => (dispatch) => {
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

export const setAppealDocCount = (appealId, docCount, cached) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCount,
    cached
  }
});

export const setMostRecentlyHeldHearingForAppeal = (appealId, hearing) => ({
  type: ACTIONS.SET_MOST_RECENTLY_HELD_HEARING_FOR_APPEAL,
  payload: prepareMostRecentlyHeldHearingForStore(appealId, hearing)
});

export const setDecisionOptions = (opts) => (dispatch) => {
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

export const deleteAppeal = (appealId) => ({
  type: ACTIONS.DELETE_APPEAL,
  payload: {
    appealId
  }
});

export const editStagedAppeal = (appealId, attributes) => ({
  type: ACTIONS.EDIT_STAGED_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const checkoutStagedAppeal = (appealId) => ({
  type: ACTIONS.CHECKOUT_STAGED_APPEAL,
  payload: {
    appealId
  }
});

export const stageAppeal = (appealId) => (dispatch) => {
  dispatch(checkoutStagedAppeal(appealId));

  dispatch({
    type: ACTIONS.STAGE_APPEAL,
    payload: {
      appealId
    }
  });
};

export const updateEditingAppealIssue = (attributes) => ({
  type: ACTIONS.UPDATE_EDITING_APPEAL_ISSUE,
  payload: {
    attributes
  }
});

export const startEditingAppealIssue =
  (appealId, issueId, attributes) => (dispatch) => {
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
  (appealId, issueId, attributes) => (dispatch) => {
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

export const saveEditedAppealIssue = (appealId, attributes) => (dispatch) => {
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

export const setAttorneysOfJudge = (attorneys) => ({
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

export const errorFetchingDocumentCount = (appealId) => ({
  type: ACTIONS.ERROR_ON_RECEIVE_DOCUMENT_COUNT,
  payload: {
    appealId
  }
});

export const fetchTasksAndAppealsOfAttorney = (attorneyId, params) => (dispatch) => {
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
  ({ userId, taskId, selected }) => ({
    type: ACTIONS.SET_SELECTION_OF_TASK_OF_USER,
    payload: {
      userId,
      taskId,
      selected
    }
  });

export const initialAssignTasksToUser = ({
  tasks, assigneeId, previousAssigneeId
}) => (dispatch) => Promise.all(tasks.map((oldTask) => {
  let params, url;

  if (oldTask.appealType === 'Appeal') {
    url = '/tasks';
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
}) => (dispatch) => Promise.all(tasks.map((oldTask) => {
  let params, url;

  if (oldTask.appealType === 'Appeal') {
    url = `/tasks/${oldTask.taskId}`;
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

const refreshTasks = (dispatch, userId, userRole) => {
  return Promise.all([
    ApiUtil.get(`/tasks?user_id=${userId}&role=${userRole}`),
    ApiUtil.get(`/queue/${userId}`, { timeout: { response: 5 * 60 * 1000 } })
  ]).then((responses) => {
    dispatch(onReceiveQueue(extractAppealsAndAmaTasks(responses[0].body.tasks.data)));
    dispatch(onReceiveQueue({
      amaTasks: {},
      ...associateTasksWithAppeals(JSON.parse(responses[1].text))
    }));
  });
};

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
    refreshTasks(dispatch, userId, 'judge').then(() => dispatch(setPendingDistribution(null)));
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
      title: 'Distribution complete',
      detail: `${caseN} new ${pluralize('case', caseN)} have been distributed from the docket.`
    }));

    refreshTasks(dispatch, userId, 'judge').then(() => dispatch(setPendingDistribution(null)));
  } else {
    setTimeout(() => {
      // Poll until the distribution completes or errors out.
      ApiUtil.get(`/distributions/${distribution.id}`).
        then((resp) => receiveDistribution(dispatch, userId, resp)).
        catch((error) => distributionError(dispatch, userId, error));
    }, 2000);
  }
};

export const requestDistribution = (userId) => (dispatch) => {
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

export const fetchAllAttorneys = () => (dispatch) =>
  ApiUtil.get('/users?role=Attorney').
    then((resp) => dispatch(receiveAllAttorneys(resp.body.attorneys))).
    catch((error) => dispatch(errorAllAttorneys(error)));

export const fetchAmaTasksOfUser = (userId, userRole) => (dispatch) =>
  ApiUtil.get(`/tasks?user_id=${userId}&role=${userRole}`).
    then((resp) => dispatch(onReceiveQueue(extractAppealsAndAmaTasks(resp.body.tasks.data))));

export const setAppealAttrs = (appealId, attributes) => ({
  type: ACTIONS.SET_APPEAL_ATTRS,
  payload: {
    appealId,
    attributes
  }
});

export const setSpecialIssues = (specialIssues) => ({
  type: ACTIONS.SET_SPECIAL_ISSUE,
  payload: {
    specialIssues
  }
});

export const setAppealAod = (externalAppealId) => ({
  type: ACTIONS.SET_APPEAL_AOD,
  payload: {
    externalAppealId
  }
});
