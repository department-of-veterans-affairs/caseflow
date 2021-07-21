/* eslint-disable max-lines */
import { associateTasksWithAppeals,
  prepareAllTasksForStore,
  extractAppealsAndAmaTasks,
  prepareMostRecentlyHeldHearingForStore,
  prepareTasksForStore } from './utils';
import { ACTIONS } from './constants';
import { hideErrorMessage, showErrorMessage, showSuccessMessage } from './uiReducer/uiActions';
import ApiUtil from '../util/ApiUtil';
import { getMinutesToMilliseconds } from '../util/DateUtil';
import _ from 'lodash';
import pluralize from 'pluralize';

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
    const judges = _.keyBy(response.body.judges, 'id');

    dispatch({
      type: ACTIONS.RECEIVE_JUDGE_DETAILS,
      payload: {
        judges
      }
    });
  });
};

export const clearAppealFromStore = (appealId) => ({
  type: ACTIONS.CLEAR_APPEAL_FROM_STORE,
  payload: {
    appealId
  }
});

export const receiveNewDocumentsForAppeal = ({ appealId, newDocuments }) => ({
  type: ACTIONS.RECEIVE_NEW_FILES_FOR_APPEAL,
  payload: {
    appealId,
    newDocuments
  }
});

export const getNewDocumentsForAppeal = (appealId) => (dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_APPEAL,
    payload: {
      appealId
    }
  });
  const requestOptions = {
    timeout: { response: getMinutesToMilliseconds(5) }
  };

  ApiUtil.get(`/appeals/${appealId}/new_documents`, requestOptions).then((response) => {
    dispatch(receiveNewDocumentsForAppeal({
      appealId,
      newDocuments: response.body.new_documents
    }));
  }, (error) => {
    dispatch({
      type: ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_APPEAL,
      payload: {
        appealId,
        error
      }
    });
  });
};

export const receiveNewDocumentsForTask = ({ taskId, newDocuments }) => ({
  type: ACTIONS.RECEIVE_NEW_FILES_FOR_TASK,
  payload: {
    taskId,
    newDocuments
  }
});

export const getNewDocumentsForTask = (taskId) => (dispatch) => {
  dispatch({
    type: ACTIONS.STARTED_LOADING_DOCUMENTS_FOR_TASK,
    payload: {
      taskId
    }
  });
  const requestOptions = {
    timeout: { response: getMinutesToMilliseconds(5) }
  };

  ApiUtil.get(`/tasks/${taskId}/new_documents`, requestOptions).then((response) => {
    dispatch(receiveNewDocumentsForTask({
      taskId,
      newDocuments: response.body.new_documents
    }));
  }, (error) => {
    dispatch({
      type: ACTIONS.ERROR_ON_RECEIVE_NEW_FILES_FOR_TASK,
      payload: {
        taskId,
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
  ApiUtil.get(`/appeals/${appealId}/${endpoint}`).then((response) => {
    dispatch({
      type: ACTIONS.RECEIVE_APPEAL_VALUE,
      payload: {
        appealId,
        name,
        response: response.body
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

export const setAppealDocCount = (appealId, docCountText) => ({
  type: ACTIONS.SET_APPEAL_DOC_COUNT,
  payload: {
    appealId,
    docCountText
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

export const editAppeal = (appealId, attributes) => ({
  type: ACTIONS.EDIT_APPEAL,
  payload: {
    appealId,
    attributes
  }
});

export const editNodDateUpdates = (appealId, nodDateUpdate) => ({
  type: ACTIONS.EDIT_NOD_DATE_UPDATES,
  payload: {
    appealId,
    nodDateUpdate
  }
});

export const clearAppealDetails = (appealId) => ({
  type: ACTIONS.CLEAR_APPEAL,
  payload: {
    appealId
  }
});

export const setOvertime = (appealId, overtime) => ({
  type: ACTIONS.SET_OVERTIME,
  payload: {
    appealId,
    overtime
  }
});

export const deleteTask = (taskId) => ({
  type: ACTIONS.DELETE_TASK,
  payload: {
    taskId
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

export const incrementTaskCountForAttorney = (attorney) => ({
  type: ACTIONS.INCREMENT_TASK_COUNT_FOR_ATTORNEY,
  payload: {
    attorney
  }
});

export const decrementTaskCountForAttorney = (attorney) => ({
  type: ACTIONS.DECREMENT_TASK_COUNT_FOR_ATTORNEY,
  payload: {
    attorney
  }
});

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
    (response) => dispatch(
      receiveTasksAndAppealsOfAttorney(
        { attorneyId,
          ...associateTasksWithAppeals(response.body) })),
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

// isInitial is only used for das deprecation
const dispatchOldTasks = (dispatch, oldTasks, resp) => {
  // Ama request is batched
  if (Array.isArray(oldTasks) || oldTasks.appealType === 'Appeal') {
    dispatch(onReceiveAmaTasks(resp.tasks.data));
  } else {
    // For das deprecation, legacy_task_controller#create returns tasks, not a task
    const tasks = resp.tasks ? resp.tasks.data : [resp.task.data];
    const allTasks = prepareAllTasksForStore(tasks);

    dispatch(onReceiveTasks({
      tasks: allTasks.tasks,
      amaTasks: allTasks.amaTasks
    }));
  }
};

export const initialAssignTasksToUser = ({
  tasks, assigneeId, previousAssigneeId, instructions
}) => (dispatch) => {
  const amaTasks = tasks.filter((oldTask) => oldTask.appealType === 'Appeal');
  const legacyTasks = tasks.filter((oldTask) => oldTask.appealType === 'LegacyAppeal');

  const amaParams = {
    url: '/judge_assign_tasks',
    taskIds: amaTasks.map((oldTask) => oldTask.uniqueId),
    requestParams: {
      data: {
        tasks: amaTasks.map((oldTask) => ({
          external_id: oldTask.externalAppealId,
          parent_id: oldTask.taskId,
          assigned_to_id: assigneeId,
          instructions
        }))
      }
    }
  };

  const legacyParams = legacyTasks.map((oldTask) => ({
    url: '/legacy_tasks',
    taskIds: [oldTask.uniqueId],
    requestParams: {
      data: {
        tasks: {
          assigned_to_id: assigneeId,
          type: 'JudgeCaseAssignmentToAttorney',
          appeal_id: oldTask.appealId,
          judge_id: previousAssigneeId
        }
      }
    }
  }));

  const paramsArray = amaParams.requestParams.data.tasks.length ? legacyParams.concat(amaParams) : legacyParams;

  return Promise.all(paramsArray.map((params) => {
    const { requestParams, url, taskIds } = params;

    return ApiUtil.post(url, requestParams).
      then((resp) => resp.body).
      then((resp) => {
        dispatchOldTasks(dispatch, requestParams.data.tasks, resp);

        taskIds.forEach((taskId) => {
          dispatch(setSelectionOfTaskOfUser({
            userId: previousAssigneeId,
            selected: false,
            taskId
          }));

          dispatch(incrementTaskCountForAttorney({
            id: assigneeId
          }));
        });
      });
  }));
};

export const reassignTasksToUser = ({
  tasks, assigneeId, previousAssigneeId, instructions
}) => (dispatch) => Promise.all(tasks.map((oldTask) => {
  let params, url;

  if (oldTask.appealType === 'Appeal') {
    url = `/tasks/${oldTask.taskId}`;
    params = {
      data: {
        task: {
          reassign: {
            assigned_to_id: assigneeId,
            assigned_to_type: 'User',
            instructions
          }
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
      dispatchOldTasks(dispatch, oldTask, resp);

      dispatch(setSelectionOfTaskOfUser({
        userId: previousAssigneeId,
        taskId: oldTask.uniqueId,
        selected: false
      }));

      dispatch(incrementTaskCountForAttorney({
        id: assigneeId
      }));

      dispatch(decrementTaskCountForAttorney({
        id: previousAssigneeId
      }));

      dispatch(setOvertime(oldTask.externalAppealId, false));
    });
}));

export const legacyReassignToJudge = ({
  tasks, assigneeId
}, successMessage) => (dispatch) => Promise.all(tasks.map((oldTask) => {
  const params = {
    data: {
      tasks: {
        assigned_to_id: assigneeId,
        appeal_id: oldTask.appealId
      }
    }
  };

  return ApiUtil.post('/legacy_tasks/assign_to_judge', params).
    then((resp) => resp.body).
    then((resp) => {
      const allTasks = prepareAllTasksForStore([resp.task.data]);

      dispatch(onReceiveTasks(_.pick(allTasks, ['tasks', 'amaTasks'])));

      dispatch(showSuccessMessage(successMessage));

      dispatch(setOvertime(oldTask.externalAppealId, false));
    });
}));

const refreshTasks = (dispatch, userId, userRole, type = null) => {
  let url = `/tasks?user_id=${userId}&role=${userRole}`;

  if (type) {
    url = url.concat(`&type=${type}`);
  }

  return Promise.all([
    ApiUtil.get(url),
    ApiUtil.get(`/queue/${userId}`, { timeout: { response: getMinutesToMilliseconds(5) } })
  ]).then((responses) => {
    dispatch(onReceiveQueue(extractAppealsAndAmaTasks(responses[0].body.tasks.data)));
    dispatch(onReceiveQueue({
      amaTasks: {},
      ...associateTasksWithAppeals(responses[1].body)
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

    refreshTasks(dispatch, userId, 'judge', 'assign').then(() => dispatch(setPendingDistribution(null)));
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

  ApiUtil.get(`/distributions/new?user_id=${userId}`).
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

export const fetchAmaTasksOfUser = (userId, userRole, type = null) => (dispatch) => {
  let url = `/tasks?user_id=${userId}&role=${userRole}`;

  if (type) {
    url = url.concat(`&type=${type}`);
  }

  return ApiUtil.get(url).
    then((resp) => {
      dispatch(onReceiveQueue(extractAppealsAndAmaTasks(resp.body.tasks.data)));
      dispatch(setQueueConfig(resp.body.queue_config));
    }).
    catch((error) => {
      dispatch(errorTasksAndAppealsOfAttorney({ attorneyId: userId, error }));
      // rethrow error so that QueueLoadingScreen can catch and display error
      throw error;
    });
};

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

export const clearSpecialIssues = () => ({
  type: ACTIONS.CLEAR_SPECIAL_ISSUE
});

export const setAppealAod = (externalAppealId, granted) => ({
  type: ACTIONS.SET_APPEAL_AOD,
  payload: {
    externalAppealId,
    granted
  }
});

export const setQueueConfig = (config) => ({ type: ACTIONS.SET_QUEUE_CONFIG,
  payload: { config } });
