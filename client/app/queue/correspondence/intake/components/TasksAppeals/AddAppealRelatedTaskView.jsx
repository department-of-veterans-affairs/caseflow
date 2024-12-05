import React, { useEffect, useState } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import { LOGO_COLORS } from '../../../../../constants/AppConstants';
import CaseListTable from '../../../../CaseListTable';
import ApiUtil from '../../../../../util/ApiUtil';
import { prepareAppealForSearchStore } from '../../../../utils';
import LoadingContainer from '../../../../../components/LoadingContainer';
import RadioField from '../../../../../components/RadioField';
import ExistingAppealTasksView from './ExistingAppealTasksView';
import {
  setFetchedAppeals,
  setNewAppealRelatedTasks,
  setTaskRelatedAppealIds,
  setWaivedEvidenceTasks
} from '../../../correspondenceReducer/correspondenceActions';
import { INTAKE_FORM_TASK_TYPES } from '../../../../constants';

const RELATED_NO = '0';
const RELATED_YES = '1';

const existingAppealAnswer = [
  { displayText: 'Yes',
    value: RELATED_YES },
  { displayText: 'No',
    value: RELATED_NO }
];

export const AddAppealRelatedTaskView = (props) => {
  const appeals = useSelector((state) => state.intakeCorrespondence.fetchedAppeals);
  const [taskRelatedAppeals, setTaskRelatedAppeals] =
    useState(useSelector((state) => state.intakeCorrespondence.taskRelatedAppealIds));
  const [newTasks, setNewTasks] = useState(useSelector((state) => state.intakeCorrespondence.newAppealRelatedTasks));
  const [waivedTasks, setWaivedTasks] =
    useState(useSelector((state) => state.intakeCorrespondence.waivedEvidenceTasks));
  const [existingAppealRadio, setExistingAppealRadio] =
    useState(taskRelatedAppeals.length ? RELATED_YES : RELATED_NO);
  const [loading, setLoading] = useState(false);
  const [nextTaskId, setNextTaskId] = useState(newTasks.length);
  const [currentAppealPage, setCurrentAppealPage] = useState(1);
  const [tableUpdateTrigger, setTableUpdateTrigger] = useState(1);

  const dispatch = useDispatch();

  const appealById = (appealId) => {
    return appeals.find((el) => el.id === appealId);
  };

  const appealsPageUpdateHandler = (newCurrentPage) => {
    setCurrentAppealPage(newCurrentPage);
    setTableUpdateTrigger((prev) => prev + 1);
  };

  useEffect(() => {
    dispatch(setTaskRelatedAppealIds(taskRelatedAppeals));
  }, [taskRelatedAppeals]);

  useEffect(() => {
    // Creates an array of Task IDs then sorts them so that the highest ID is the last in the array.
    const existingIds = [...newTasks.map((task) => task.id)].sort((task1, task2) => task1 - task2);

    // Set the value to 0 if there are no IDs. Otherwise use the highest value ID + 1
    setNextTaskId(existingIds.length === 0 ? 0 : existingIds[existingIds.length - 1] + 1);

    dispatch(setNewAppealRelatedTasks(newTasks));
  }, [newTasks]);

  useEffect(() => {
    dispatch(setWaivedEvidenceTasks(waivedTasks));
  }, [waivedTasks]);

  const appealCheckboxOnChange = (appealId, isChecked) => {
    if (isChecked) {
      if (!taskRelatedAppeals.includes(appealId)) {
        setTaskRelatedAppeals([...taskRelatedAppeals, appealId]);
      }
    } else {
      const selectedAppeals = taskRelatedAppeals.filter((checkedId) => checkedId !== appealId);
      const filteredNewTasks = newTasks.filter((task) => task.appealId !== appealId);
      const waivedEvidenceTasks = filteredNewTasks.filter((taskEvidence) => taskEvidence.isWaived);

      setTaskRelatedAppeals(selectedAppeals);
      setNewTasks(filteredNewTasks);
      setTableUpdateTrigger((prev) => prev + 1);
      setWaivedTasks(waivedEvidenceTasks);
    }
  };

  useEffect(() => {
    // Clear the selected appeals and any tasks when the user toggles the radio button
    if (existingAppealRadio === RELATED_NO) {
      setTaskRelatedAppeals([]);
      setNewTasks([]);
      setWaivedTasks([]);
    }
  }, [existingAppealRadio]);

  useEffect(() => {
    let canContinue = true;

    // Check if radio button is selected
    if (existingAppealRadio !== '0') {
      // Check if at least one checkbox is selected
      if (taskRelatedAppeals.length === 0) {
        canContinue = false;
      } else {
        // Check the conditions for each task and waived task
        canContinue = newTasks.every((task) => task.content !== '' && task.type !== '') &&
                waivedTasks.every((task) => task.isWaived ? task.waiveReason !== '' : true);
      }
    }

    props.setRelatedTasksCanContinue(canContinue);
  }, [existingAppealRadio, newTasks, waivedTasks, taskRelatedAppeals]);

  const veteranFileNumber = props.correspondence.veteranFileNumber;

  useEffect(() => {
  // Don't refetch (use cache)
    if (appeals.length) {
      return;
    }

    if (veteranFileNumber) {
    // Visually indicate that we are fetching data
      setLoading(true);

      ApiUtil.get('/appeals', { headers: { 'case-search': veteranFileNumber } }).
        then((appealResponse) => {
          const appealsForStore = prepareAppealForSearchStore(appealResponse.body.appeals);

          const appealArr = Object.values(appealsForStore.appeals).sort((first, second) => first.id - second.id);

          dispatch(setFetchedAppeals(appealArr));
          setLoading(false);
        });
    }
  }, [veteranFileNumber]);

  return (
    <div style={{ marginBottom: '0rem' }}>
      <RadioField
        name=""
        value={existingAppealRadio}
        options={existingAppealAnswer}
        onChange={(val) => setExistingAppealRadio(val)}
      />
      {existingAppealRadio === RELATED_YES && loading &&
        <LoadingContainer color={LOGO_COLORS.QUEUE.ACCENT}>
          <div className="loading-div">
          </div>
        </LoadingContainer>
      }
      {existingAppealRadio === RELATED_YES && !loading &&
        <div className="gray-border corr"
          style={{ padding: '0rem 0rem', display: 'flex', flexWrap: 'wrap', flexDirection: 'column' }}>
          <div className="entire-tasks-related-to-existing-appeals">
            <div className="existing-appeals-box">
              <div className="bottom-of-existing-appeals-title">
                <b className="existing-appeals-title">Existing Appeals</b>
              </div>
              <ul className="selection-for-prior-appeals-linked-to-corr">
              Please select prior appeal(s) to link to this correspondence
              </ul>
              <ul className="left-side-of-docket">
                <div className="right-side-of-assigned-to" >
                  <CaseListTable
                  // Need to use this as key to force React to re-render checkboxes
                    key={tableUpdateTrigger}
                    appeals={appeals}
                    showCheckboxes
                    paginate
                    linkOpensInNewTab
                    checkboxOnChange={appealCheckboxOnChange}
                    taskRelatedAppealIds={taskRelatedAppeals}
                    currentPage={currentAppealPage}
                    updatePageHandlerCallback={appealsPageUpdateHandler}
                  />
                </div>
              </ul>
            </div>
            <div>
              {taskRelatedAppeals.toSorted().map((appealId, index) => {
                return (
                  <ExistingAppealTasksView
                    key={index}
                    appeal={appealById(appealId)}
                    newTasks={newTasks}
                    setNewTasks={setNewTasks}
                    waivedTasks={waivedTasks}
                    setWaivedTasks={setWaivedTasks}
                    nextTaskId={nextTaskId}
                    setRelatedTasksCanContinue={props.setRelatedTasksCanContinue}
                    unlinkAppeal={appealCheckboxOnChange}
                    allTaskTypeOptions={
                      appealById(appealId).active ? props.allTaskTypeOptions :
                        INTAKE_FORM_TASK_TYPES.relatedToAppealInactive
                    }
                    filterUnavailableTaskTypeOptions={props.filterUnavailableTaskTypeOptions}
                    autoTexts={props.autoTexts}
                  />
                );
              })}
            </div>
          </div>
        </div>
      }
    </div>
  );
};

AddAppealRelatedTaskView.propTypes = {
  correspondence: PropTypes.object.isRequired,
  setRelatedTasksCanContinue: PropTypes.func.isRequired,
  filterUnavailableTaskTypeOptions: PropTypes.func.isRequired,
  allTaskTypeOptions: PropTypes.array.isRequired,
  autoTexts: PropTypes.arrayOf(PropTypes.string).isRequired,
};

export default AddAppealRelatedTaskView;
