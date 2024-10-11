/* eslint-disable max-lines */
import React, { useState, useEffect } from 'react';
import { useDispatch, connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import TabWindow from '../../../components/TabWindow';
import CopyTextButton from '../../../components/CopyTextButton';
import CorrespondenceCaseTimeline from '../CorrespondenceCaseTimeline';
import { updateCorrespondenceInfo } from './../correspondenceDetailsReducer/correspondenceDetailsActions';
import CorrespondenceResponseLetters from './CorrespondenceResponseLetters';
import COPY from '../../../../COPY';
import CaseListTable from 'app/queue/CaseListTable';
import { prepareAppealForStore, prepareTasksForStore } from 'app/queue/utils';
import { onReceiveTasks, onReceiveAppealDetails } from '../../QueueActions';
import moment from 'moment';
import Pagination from 'app/components/Pagination/Pagination';
import Table from 'app/components/Table';
import { ExternalLinkIcon } from 'app/components/icons/ExternalLinkIcon';
import { COLORS } from 'app/constants/AppConstants';
import Checkbox from 'app/components/Checkbox';
import CorrespondencePaginationWrapper from 'app/queue/correspondence/CorrespondencePaginationWrapper';
import Button from '../../../components/Button';
import Alert from '../../../components/Alert';
import ApiUtil from '../../../util/ApiUtil';
import CorrespondenceEditGeneralInformationModal from '../../components/CorrespondenceEditGeneralInformationModal';
import CorrespondenceAppealTasks from '../CorrespondenceAppealTasks';

const CorrespondenceDetails = (props) => {
  const dispatch = useDispatch();
  const correspondence = props.correspondence;
  const correspondenceInfo = props.correspondenceInfo;
  const mailTasks = props.correspondence.mailTasks;
  const allCorrespondences = props.correspondence.all_correspondences;
  const [viewAllCorrespondence, setViewAllCorrespondence] = useState(false);
  const [editGeneralInformationModal, setEditGeneralInformationModal] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const [disableSubmitButton, setDisableSubmitButton] = useState(true);
  const [showSuccessBanner, setShowSuccessBanner] = useState(false);
  const [selectedPriorMail, setSelectedPriorMail] = useState([]);
  const totalPages = Math.ceil(allCorrespondences.length / 15);
  const startIndex = (currentPage * 15) - 15;
  const endIndex = (currentPage * 15);
  const priorMail = correspondence.prior_mail;
  // eslint-disable-next-line max-len
  const [relatedCorrespondenceIds, setRelatedCorrespondenceIds] = useState(props.correspondence.relatedCorrespondenceIds);
  const [initialSelectedAppeals, setInitialSelectedAppeals] = useState(correspondence.correspondenceAppealIds);
  const [selectedAppeals, setSelectedAppeals] = useState(correspondence.correspondenceAppealIds);
  const [unSelectedAppeals, setUnSelectedAppeals] = useState([]);
  const [appealsToDisplay, setAppealsToDisplay] = useState([]);
  const [appealTableKey, setAppealTableKey] = useState(0);
  const userAccess = correspondence.user_access;

  const [checkboxStates, setCheckboxStates] = useState({});
  const [originalStates, setOriginalStates] = useState({});
  const [sortedPriorMail, setSortedPriorMail] = useState([]);
  const [isExpanded, setIsExpanded] = useState(false);
  const [isTasksUnrelatedSectionExpanded, setIsTasksUnrelatedSectionExpanded] = useState(false);
  const [appealTaskKey, setAppealTaskKey] = useState(0);

  // Initialize checkbox states
  useEffect(() => {
    const initialStates = {};

    correspondence.prior_mail.forEach((mail) => {
      initialStates[mail.id] = relatedCorrespondenceIds.includes(mail.id);
    });
    setCheckboxStates(initialStates);
    setOriginalStates(initialStates);
  }, [priorMail, relatedCorrespondenceIds]);

  useEffect(() => {
    // Initialize sortedPriorMail with the initial priorMail list
    setSortedPriorMail(priorMail);
  }, [priorMail]);

  useEffect(() => {
    dispatch(updateCorrespondenceInfo(correspondence));
  }, [correspondenceInfo]);

  const toggleSection = () => {
    setIsExpanded((prev) => !prev);
  };

  const toggleTasksUnrelatedSection = () => {
    setIsTasksUnrelatedSectionExpanded((prev) => !prev);
  };

  // Function to handle checkbox changes
  const handleCheckboxChange = (mailId) => {
    setCheckboxStates((prevState) => {
      const newState = { ...prevState, [mailId]: !prevState[mailId] };

      // Check if any checkbox is different from its original state
      const isAnyChanged = Object.keys(newState).some(
        (key) => newState[key] !== originalStates[key]
      );

      setDisableSubmitButton(!isAnyChanged);

      return newState;
    });
  };

  // Function to handle the "Save Changes" button click, including the PATCH and POST request
  const handlepriorMailUpdate = async () => {
  // Disable the button to prevent duplicate requests
    setDisableSubmitButton(true);

    // Get the initial and current checkbox states
    const uncheckedCheckboxes = Object.entries(checkboxStates).
      filter(([mailId, isChecked]) => !isChecked && originalStates[mailId]).
      map(([mailId]) => {
        const mail = priorMail.find((pMail) => pMail.id === parseInt(mailId, 10));

        return { uuid: mail.uuid };
      });

    const checkedCheckboxes = Object.entries(checkboxStates).
      filter(([mailId, isChecked]) => isChecked && !originalStates[mailId]).
      map(([mailId]) => {
        const mail = priorMail.find((pMail) => pMail.id === parseInt(mailId, 10));

        return mail.id;
      });

    // Data for the PATCH request to remove unchecked relations
    const patchData = {
      correspondence_uuid: correspondence.uuid,
      correspondence_relations: uncheckedCheckboxes
    };

    // Data for the POST request to add checked relations
    const postData = {
      priorMailIds: checkedCheckboxes
    };

    try {
    // Helper function to check for success response
      const isSuccess = (response) => response.ok;

      // Send PATCH request to remove unchecked relations if necessary
      // If no unchecked items, PATCH is already successful
      let patchSuccess = uncheckedCheckboxes.length === 0;

      if (uncheckedCheckboxes.length > 0) {
      // Send PATCH request to update the backend
        const patchResponse = await ApiUtil.patch(
        `/queue/correspondence/${correspondence.uuid}/update_correspondence`,
        { data: patchData }
        );

        // Check for general success status (any 2xx status)
        patchSuccess = isSuccess(patchResponse);
        console.log('PATCH successful:', patchResponse.status); // eslint-disable-line no-console
      }

      // Send POST request to add checked relations if necessary
      // If no checked items, POST is already successful
      let postSuccess = checkedCheckboxes.length === 0;

      if (checkedCheckboxes.length > 0) {
      // Send POST request to create relations
        const postResponse = await ApiUtil.post(
        `/queue/correspondence/${correspondence.uuid}/create_correspondence_relations`,
        { data: postData }
        );

        // Check for general success status (any 2xx status)
        postSuccess = isSuccess(postResponse);
        console.log('POST successful:', postResponse.status); // eslint-disable-line no-console
      }

      // Only show success banner if both PATCH and POST requests succeeded
      if (patchSuccess && postSuccess) {
        setShowSuccessBanner(true);
      }

      // Sort the prior mail into linked (checked) and unlinked (unchecked) groups
      const updatedSortedPriorMail = [...priorMail].sort((first, second) => {
        const firstInState = checkboxStates[first.id];
        const secondInState = checkboxStates[second.id];

        // Default sorting order
        let sortOrder = 0;

        if (firstInState && secondInState) {
        // Sort linked mail from most recent to oldest
          sortOrder = new Date(second.vaDateOfReceipt) - new Date(first.vaDateOfReceipt);
        } else if (!firstInState && !secondInState) {
        // Sort unlinked mail from oldest to most recent
          sortOrder = new Date(first.vaDateOfReceipt) - new Date(second.vaDateOfReceipt);
        } else if (firstInState) {
        // Ensure linked items come before unlinked items
          sortOrder = -1;
        } else if (secondInState) {
          sortOrder = 1;
        }

        // Single return for sorting
        return sortOrder;
      });

      // Update the state with the sorted list after saving changes
      setSortedPriorMail(updatedSortedPriorMail);
    } catch (error) {
      console.error('Error during PATCH/POST request:', error.message); // eslint-disable-line no-console
    } finally {
      // Re-enable the button
      setDisableSubmitButton(true);
    }

    // Reset checkboxes to the new state
    setOriginalStates(checkboxStates);
  };

  const isAdminNotLoggedIn = () => {
    if (props.isInboundOpsSuperuser || props.isInboundOpsSupervisor === true) {
      return false;
    }

    return true;

  };

  priorMail.sort((first, second) => {
    const firstInRelated = relatedCorrespondenceIds.includes(first.id);
    const secondInRelated = relatedCorrespondenceIds.includes(second.id);

    if (firstInRelated && secondInRelated) {
      // Sort by vaDateOfReceipt in descending order if both are in relatedCorrespondenceIds
      return new Date(second.vaDateOfReceipt) - new Date(first.vaDateOfReceipt);
    } else if (firstInRelated) {
      // Ensure that items in relatedCorrespondenceIds come first
      return -1;
    } else if (secondInRelated) {
      return 1;
    }
    if (!firstInRelated && secondInRelated) {
      return 1;
    }

    // If neither is in relatedCorrespondenceIds, maintain their original order
    const returnSort = priorMail.indexOf(first) - priorMail.indexOf(second);

    return returnSort;
  });

  const updatePageHandler = (idx) => {
    const newCurrentPage = idx + 1;

    setCurrentPage(newCurrentPage);
  };

  const getKeyForRow = (rowNumber, object) => object.id;

  const getColumns = () => {
    const columns = [];

    columns.push(
      {
        header: 'Package Document Type',
        valueFunction: (correspondenceObj) => (
          <span className="va-package-document-type-item">
            <p>
              <a href={`/queue/correspondence/${correspondenceObj.uuid}`} rel="noopener noreferrer" target="_blank">
                <b>{correspondenceObj.nod ? 'NOD' : 'Non-NOD'}</b>
                <span className="external-link-icon-wrapper">
                  <ExternalLinkIcon color={COLORS.FOCUS_OUTLINE} />
                </span>
              </a>
            </p>
          </span>
        )
      },
      {
        header: 'VA DOR',
        valueFunction: (correspondenceObj) => {
          const date = new Date(correspondenceObj.vaDateOfReceipt);
          const year = date.getFullYear();
          const month = String(date.getMonth() + 1).padStart(2, '0');
          const day = String(date.getDate()).padStart(2, '0');

          return `${month}/${day}/${year}`;
        }
      },
      {
        header: 'Notes',
        valueFunction: (correspondenceObj) => correspondenceObj.notes
      },
      {
        header: 'Status',
        valueFunction: (correspondenceObj) => correspondenceObj.status
      }
    );

    return columns;
  };

  const handleViewAllCorrespondence = () => {
    setViewAllCorrespondence(!viewAllCorrespondence);
  };

  const viewDisplayText = () => {
    return viewAllCorrespondence ? 'Hide all correspondence' : 'View all correspondence';
  };

  const allCorrespondencesList = () => {
    return viewAllCorrespondence && (
      <div className="all-correspondences">
        <h2>{COPY.ALL_CORRESPONDENCES}</h2>
        <AppSegment filledBackground noMarginTop>
          <Pagination
            pageSize={15}
            currentPage={currentPage}
            currentCases={allCorrespondences.slice(startIndex, endIndex).length}
            totalPages={totalPages}
            totalCases={allCorrespondences.length}
            updatePage={updatePageHandler}
            table={
              <Table
                className="cf-case-list-table"
                columns={getColumns}
                rowObjects={allCorrespondences.slice(startIndex, endIndex)}
                getKeyForRow={getKeyForRow}
              />
            }
            enableTopPagination = {false}
          />
        </AppSegment>
      </div>
    );
  };

  const appealCheckboxOnChange = (appealId, isChecked) => {
    setDisableSubmitButton(false);
    if (isChecked) {
      if (unSelectedAppeals?.includes(appealId)) {
        const filtedAppeals = unSelectedAppeals.filter((item) => item !== appealId);

        setUnSelectedAppeals(filtedAppeals);
      }
      setSelectedAppeals([...selectedAppeals, appealId]);
    } else {
      if (selectedAppeals?.includes(appealId)) {
        const filtedAppeals = selectedAppeals.filter((item) => item !== appealId);

        setSelectedAppeals(filtedAppeals);
      }
      setUnSelectedAppeals([...unSelectedAppeals, appealId]);
    }
  };

  useEffect(() => {
    const isButtonDisabled = () => {
      if (selectedAppeals?.length !== initialSelectedAppeals?.length) {
        return false;
      }

      return initialSelectedAppeals.every((appeal) => selectedAppeals.includes(appeal));
    };

    setDisableSubmitButton(isButtonDisabled());
  }, [selectedAppeals, initialSelectedAppeals]);

  const sortAppeals = (selectedList) => {
    let filteredAppeals = [];
    let unfilteredAppeals = [];

    correspondence.appeals_information.map((appeal) => {
      if (selectedList?.includes(Number(appeal.id))) {
        filteredAppeals.push(appeal);
      } else {
        unfilteredAppeals.push(appeal);
      }

      return true;
    });

    filteredAppeals = filteredAppeals.sort((leftAppeal, rightAppeal) => leftAppeal.id - rightAppeal.id);
    unfilteredAppeals = unfilteredAppeals.sort((leftAppeal, rightAppeal) => leftAppeal.id - rightAppeal.id);

    const sortedAppeals = filteredAppeals.concat(unfilteredAppeals);

    setAppealsToDisplay(sortedAppeals);
  };

  useEffect(() => {
    sortAppeals(initialSelectedAppeals);
  }, []);

  useEffect(() => {
    dispatch(updateCorrespondenceInfo(correspondence));
    // load appeals related to the correspondence into the store
    const corAppealTasks = [];

    props.correspondence.correspondenceAppeals.map((corAppeal) => {
      dispatch(onReceiveAppealDetails(prepareAppealForStore([corAppeal.appeal.data])));
      corAppeal.taskAddedData.data.map((taskData) => {
        const formattedTask = {};

        formattedTask[taskData.id] = taskData;

        corAppealTasks.push(taskData);
      });

    });
    // // load appeal tasks into the store
    const preparedTasks = prepareTasksForStore(corAppealTasks);

    dispatch(onReceiveTasks({
      amaTasks: preparedTasks
    }));

  }, []);

  const isTasksUnrelatedToAppealEmpty = () => {
    if (props.tasksUnrelatedToAppealEmpty === true) {
      return 'Completed';
    }

    return props.correspondence.status;
  };

  const correspondenceTasks = () => {
    return (
      <React.Fragment>
        <div className="correspondence-mail-tasks">
          <h2>Completed Mail Tasks</h2>
          <AppSegment filledBackground noMarginTop>
            <ul
              className={`${mailTasks.length > 2 ? 'grid-list' : ''}`}
              aria-label={COPY.CORRESPONDENCE_DETAILS.COMPLETED_MAIL_TASKS} role="list" aria-live="polite"
            >
              {
                mailTasks.length > 0 ?
                  mailTasks.map((item, index) => (
                    <li key={index} role="listitem" aria-label={`Task ${index + 1}: ${item}`} >{item}</li>
                  )) :
                  <li aria-label= {COPY.CORRESPONDENCE_DETAILS.NO_COMPLETED_MAIL_TASKS} role="listitem">
                    {COPY.CORRESPONDENCE_DETAILS.NO_COMPLETED_MAIL_TASKS}
                  </li>
              }
            </ul>
          </AppSegment>
        </div>
        <div className="correspondence-existing-appeals">
          <div className="left-section">
            <h2>Existing appeals</h2>
            <div className="correspondence-details-view-documents">
              <a
                rel="noopener noreferrer"
                target="_blank"
                href={`/reader/appeal/${correspondence.veteranFileNumber}`}
              >
                View veteran documents
                <div className="external-link-icon-wrapper">
                  <ExternalLinkIcon color={COLORS.PRIMARY} />
                </div>
              </a>
            </div>
          </div>
          <div className="toggleButton-plus-or-minus">
            <Button
              onClick={toggleSection}
              linkStyling
              aria-label="Toggle section"
              aria-expanded={isExpanded}
            >
              {isExpanded ? '_' : <span className="plus-symbol">+</span>}
            </Button>
          </div>
        </div>
        <div className="collapse-section-container">
          {isExpanded && (
            <AppSegment filledBackground noMarginTop>
              <p className="correspondence-details-p">
                Please select prior appeal(s) to link to this correspondence.
              </p>
              <CaseListTable
                key={appealTableKey}
                appeals={appealsToDisplay}
                paginate
                showCheckboxes
                taskRelatedAppealIds={selectedAppeals}
                initialAppealIds={initialSelectedAppeals}
                enableTopPagination
                userAccess={userAccess}
                checkboxOnChange={appealCheckboxOnChange}
              />
            </AppSegment>
          )}
          {(props.correspondence.correspondenceAppeals.map((taskAdded) =>
            <CorrespondenceAppealTasks
              task_added={taskAdded}
              correspondence={props.correspondence}
              organizations={props.organizations}
              userCssId={props.userCssId}
              appeal={taskAdded.appeal.data.attributes}
              waivableUser={props.isInboundOpsSuperuser || props.isInboundOpsSupervisor}
              correspondence_uuid={props.correspondence_uuid}
            />
          )
          )}
        </div>
      </React.Fragment>
    );
  };
  const correspondenceAndAppealTaskComponents = <>
    {correspondenceTasks()}

    <div className="correspondence-existing-appeals">
      <div className="left-section">
        <h2>Tasks not related to an appeal</h2>
      </div>
      <div className="toggleButton-plus-or-minus">
        <Button
          onClick={toggleTasksUnrelatedSection}
          linkStyling
          aria-label="Toggle section"
          aria-expanded={isTasksUnrelatedSectionExpanded}
        >
          {isTasksUnrelatedSectionExpanded ? '_' : <span className="plus-symbol">+</span>}
        </Button>
      </div>
    </div>
    {isTasksUnrelatedSectionExpanded && (
      <div className="correspondence-case-timeline-container">
        <CorrespondenceCaseTimeline
          organizations={props.organizations}
          userCssId={props.userCssId}
          correspondence={props.correspondence}
          tasksToDisplay={props.correspondence.tasksUnrelatedToAppeal}
        />
      </div>
    )}
  </>;

  const handleEditGeneralInformationModal = () => {
    setEditGeneralInformationModal(!editGeneralInformationModal);
  };

  const correspondencePackageDetails = () => {
    return (
      <>
        <div className="correspondence-package-details">
          <div className="corr-title-with-button">
            <h2 className="correspondence-h2">General Information</h2>
            {isAdminNotLoggedIn() ?
              '' :
              <Button
                onClick={handleEditGeneralInformationModal}
                classNames={['button-style']}
              >Edit</Button> }
          </div>
          <table className="corr-table-borderless-no-background gray-border">
            <tbody>
              <tr>
                <th className="corr-table-borderless-first-item"><strong>Veteran Details</strong></th>
                <th><strong>Correspondence Type</strong></th>
                <th><strong>Package Document Type</strong></th>
                <th className="corr-table-borderless-last-item"><strong>VA DOR</strong></th>
              </tr>
              <tr>
                <td className="corr-table-borderless-first-item">
                  {correspondenceInfo?.veteranFullName} ({correspondenceInfo?.veteranFileNumber})
                </td>
                <td>{correspondenceInfo?.correspondenceType}</td>
                <td>{correspondenceInfo?.nod ? 'NOD' : 'Non-NOD'}</td>
                <td className="corr-table-borderless-last-item">
                  {moment(correspondenceInfo?.vaDateOfReceipt).format('MM/DD/YYYY')}
                </td>
              </tr>
              <tr>
                <th colSpan={6} className="corr-table-borderless-first-item corr-table-borderless-last-item">
                  <strong>Notes</strong></th>
              </tr>
              <tr>
                <td colSpan={6} className="corr-table-borderless-first-item corr-table-borderless-last-item">
                  {correspondenceInfo?.notes}</td>
              </tr>
            </tbody>
          </table>
          {editGeneralInformationModal && (
            <CorrespondenceEditGeneralInformationModal
              correspondenceTypes={props.correspondenceTypes}
              handleEditGeneralInformationModal={handleEditGeneralInformationModal}
            />
          )}
        </div>
      </>
    );
  };

  const correspondenceResponseLetters = () => {
    return (
      <>
        <div className="correspondence-response-letters">
          <CorrespondenceResponseLetters
            letters={props.correspondenceResponseLetters}
            addLetterCheck={props.addLetterCheck}
            isInboundOpsSuperuser={props.isInboundOpsSuperuser}
            isInboundOpsSupervisor={props.isInboundOpsSupervisor}
            isInboundOpsUser={props.isInboundOpsUser}
            correspondence={props.correspondence}
          />
        </div>
      </>
    );
  };

  const onPriorMailCheckboxChange = (corr, isChecked) => {
    // props.savePriorMailCheckboxState(corr, isChecked);
    let selectedCheckboxes = [...selectedPriorMail];

    if (isChecked) {
      selectedCheckboxes.push(corr);
    } else {
      selectedCheckboxes = selectedCheckboxes.filter((checkbox) => checkbox.id !== corr.id);
    }
    setSelectedPriorMail(selectedCheckboxes);
    const isAnyCheckboxSelected = selectedCheckboxes.length > 0;

    setDisableSubmitButton(!isAnyCheckboxSelected);
  };

  const getDocumentColumns = (correspondenceRow) => {
    return [
      {
        cellClass: 'checkbox-column',
        valueFunction: () => (
          <div className="checkbox-column-inline-style">
            {
              isAdminNotLoggedIn() ?
                <Checkbox
                  name={correspondenceRow.id.toString()}
                  id={correspondenceRow.id.toString()}
                  hideLabel
                  defaultValue={relatedCorrespondenceIds.some((el) => el === correspondenceRow.id)}
                  value={
                    selectedPriorMail.some((el) => el.id === correspondenceRow.id) ||
                  relatedCorrespondenceIds.some((corrId) => corrId === correspondenceRow.id)
                  }
                  disabled={
                    relatedCorrespondenceIds.some((corrId) => corrId === correspondenceRow.id) ||
                  !props.isInboundOpsUser
                  }
                  onChange={(checked) => onPriorMailCheckboxChange(correspondenceRow, checked)}
                /> :
                <Checkbox
                  name={correspondenceRow.id.toString()}
                  id={correspondenceRow.id.toString()}
                  hideLabel
                  defaultValue={relatedCorrespondenceIds.some((el) => el === correspondenceRow.id)}
                  value={checkboxStates[correspondenceRow.id]}
                  onChange={() => handleCheckboxChange(correspondenceRow.id)}
                  disabled= {isAdminNotLoggedIn()}
                />
            }
          </div>
        )
      },
      {
        cellClass: 'va-dor-column',
        ariaLabel: 'va-dor-header-label',
        header: (
          <div id="va-dor-header">
            <span id="va-dor-header-label" className="table-header-label">
              VA DOR
            </span>
          </div>
        ),
        valueFunction: () => {
          const date = new Date(correspondenceRow.vaDateOfReceipt);

          return (
            <span className="va-dor-item">
              <p>{date.toLocaleDateString('en-US')}</p>
            </span>
          );
        }
      },
      {
        cellClass: 'package-document-type-column',
        ariaLabel: 'package-document-type-header-label',
        header: (
          <div id="package-document-type-header">
            <span id="package-document-type-header-label" className="table-header-label">
              Package Document Type
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-package-document-type-item">
            <p>
              <a
                href={`/queue/correspondence/${correspondenceRow.uuid}`}
                rel="noopener noreferrer"
                className="external-link-icon-a"
                target="_blank"
              >
                {correspondenceRow?.nod ? 'NOD' : 'Non-NOD'}
                <span className="external-link-icon-wrapper">
                  <ExternalLinkIcon color={COLORS.PRIMARY} />
                </span>
              </a>
            </p>
          </span>
        )
      },
      {
        cellClass: 'correspondence-type-column',
        ariaLabel: 'correspondence-type-header-label',
        header: (
          <div id="correspondence-type-header">
            <span id="correspondence-type-header-label" className="table-header-label">
              Correspondence Type
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-correspondence-type-item">
            <p>{correspondenceRow.correspondenceType}</p>
          </span>
        )
      },
      {
        cellClass: 'notes-column',
        ariaLabel: 'notes-header-label',
        header: (
          <div id="notes-header">
            <span id="notes-header-label" className="table-header-label">
              Notes
            </span>
          </div>
        ),
        valueFunction: () => (
          <span className="va-notes-item">
            <p>{correspondenceRow.notes}</p>
          </span>
        )
      }
    ];
  };

  const associatedPriorMail = () => {
    return (
      <>
        <div className="associatedPriorMail" style = {{ marginTop: '30px' }}>
          <AppSegment filledBackground noMarginTop>
            <p style = {{ marginTop: 0 }}>Please select prior mail to link to this correspondence </p>
            <div>
              <CorrespondencePaginationWrapper
                columns={getDocumentColumns}
                columnsToDisplay={15}
                rowObjects={sortedPriorMail}
                summary="Correspondence list"
                className="correspondence-table"
                headerClassName="cf-correspondence-list-header-row"
                bodyClassName="cf-correspondence-list-body"
                tbodyId="correspondence-table-body"
                getKeyForRow={getKeyForRow}
              />
            </div>
          </AppSegment>
        </div>
      </>
    );
  };

  const tabList = [
    {
      disable: false,
      label: 'Correspondence and Appeal Tasks',
      page: correspondenceAndAppealTaskComponents
    },
    {
      disable: false,
      label: 'Package Details',
      page: correspondencePackageDetails()
    },
    {
      disable: false,
      label: 'Response Letters',
      page: correspondenceResponseLetters()
    },
    {
      disable: false,
      label: 'Associated Prior Mail',
      page: associatedPriorMail()
    }
  ];

  const saveChanges = () => {
    if (isAdminNotLoggedIn() === false) {
      handlepriorMailUpdate();
    } else if (selectedPriorMail.length > 0) {

      const priorMailIds = selectedPriorMail.map((mail) => mail.id);
      const payload = {
        data: {
          priorMailIds: selectedPriorMail.map((mail) => mail.id)
        }
      };

      const tempCor = props.correspondence;

      tempCor.relatedCorrespondenceIds = priorMailIds;

      return ApiUtil.post(`/queue/correspondence/${correspondence.uuid}/create_correspondence_relations`, payload).
        then(() => {
          props.updateCorrespondenceInfo(tempCor);
          setRelatedCorrespondenceIds([...relatedCorrespondenceIds, ...priorMailIds]);
          setShowSuccessBanner(true);
          setSelectedPriorMail([]);
          setDisableSubmitButton(true);
          window.scrollTo({
            top: 0,
            behavior: 'smooth'
          });
        }).
        catch((error) => {
          const errorMessage = error?.response?.body?.message ?
            error.response.body.message.replace(/^Error:\s*/, '') :
            error.message;

          console.error(errorMessage);
        });
    }

    if (selectedAppeals.length > 0 || unSelectedAppeals.length > 0) {
      const appealsSelected = selectedAppeals.filter((val) => !correspondence.correspondenceAppealIds.includes(val));

      const payload = {
        data: {
          selected_appeal_ids: appealsSelected,
          unselected_appeal_ids: unSelectedAppeals
        }
      };

      return ApiUtil.post(`/queue/correspondence/${correspondence.uuid}/save_correspondence_appeals`, payload).
        then((resp) => {
          const appealIds = resp.body;

          setSelectedAppeals(appealIds);
          setInitialSelectedAppeals(appealIds);
          sortAppeals(appealIds);
          setShowSuccessBanner(true);
          setDisableSubmitButton(true);
          setAppealTableKey((key) => key + 1);
          window.scrollTo({
            top: 0,
            behavior: 'smooth'
          });
        }).
        catch((error) => {
          const errorMessage = error?.response?.body?.message ?
            error.response.body.message.replace(/^Error:\s*/, '') :
            error.message;

          console.error(errorMessage);
        });
    }
  };

  const customSuccessBannerStyles = {
    style: {
      backgroundPosition: '2rem 1.8rem'
    }
  };

  return (
    <>
      {
        showSuccessBanner &&
          <div style={{ padding: '10px' }}>
            <Alert
              type="success"
              title={COPY.CORRESPONDENCE_DETAILS.SAVE_CHANGES_BANNER.MESSAGE}
              styling={customSuccessBannerStyles}
            />
          </div>
      }
      <AppSegment filledBackground extraClassNames="app-segment-cd-details">
        <div className="correspondence-details-header">
          <h1> {correspondence?.veteranFullName} </h1>
          <div className="copy-id">
            <p className="vet-id-margin">Veteran ID:</p>
            <CopyTextButton
              label="copy-id"
              text={props.correspondence.veteranFileNumber}
            />
          </div>
          <p><a onClick={handleViewAllCorrespondence}>{viewDisplayText()}</a></p>
          <div></div>
          <p className="last-item"><b>Record status: </b>{isTasksUnrelatedToAppealEmpty()}</p>
        </div>
        <div style = {{ marginTop: '20px' }}>
          { allCorrespondencesList() }
        </div>
        <TabWindow
          name="tasks-tabwindow"
          tabs={tabList}
        />
      </AppSegment>
      {
        // eslint-disable-next-line max-len
        (props.isInboundOpsUser || props.isInboundOpsSuperuser || props.isInboundOpsSupervisor) && <div className="margin-top-for-add-task-view">
          <Button
            type="button"
            onClick={() => saveChanges()}
            disabled={disableSubmitButton}
            name="save-changes"
            classNames={['cf-right-side']}>
          Save changes
          </Button>
        </div>
      }
    </>
  );
};

CorrespondenceDetails.propTypes = {
  correspondence: PropTypes.object,
  correspondenceInfo: PropTypes.object,
  organizations: PropTypes.array,
  userCssId: PropTypes.string,
  enableTopPagination: PropTypes.bool,
  isInboundOpsUser: PropTypes.bool,
  tasksUnrelatedToAppealEmpty: PropTypes.bool,
  isInboundOpsSuperuser: PropTypes.bool,
  isInboundOpsSupervisor: PropTypes.bool,
  correspondenceResponseLetters: PropTypes.array,
  inboundOpsTeamUsers: PropTypes.array,
  addLetterCheck: PropTypes.bool,
  updateCorrespondenceInfo: PropTypes.func,
  correspondenceTypes: PropTypes.array,
  correspondence_uuid: PropTypes.string
};

const mapStateToProps = (state) => ({
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  tasksUnrelatedToAppealEmpty: state.correspondenceDetails.tasksUnrelatedToAppealEmpty
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    updateCorrespondenceInfo
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceDetails);

/* eslint-enable max-lines */
