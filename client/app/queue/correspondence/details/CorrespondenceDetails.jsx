/* eslint-disable max-lines */
import React, { useState, useEffect } from 'react';
import { useDispatch, connect } from 'react-redux';
import { bindActionCreators } from 'redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import TabWindow from '../../../components/TabWindow';
import CopyTextButton from '../../../components/CopyTextButton';
import { loadCorrespondence } from '../correspondenceReducer/correspondenceActions';
import CorrespondenceCaseTimeline from '../CorrespondenceCaseTimeline';
import { correspondenceInfo } from './../correspondenceDetailsReducer/correspondenceDetailsActions';
import CorrespondenceResponseLetters from './CorrespondenceResponseLetters';
import COPY from '../../../../COPY';
import CaseListTable from 'app/queue/CaseListTable';
// import TaskSnapshot from '../../TaskSnapshot';
import { prepareAppealForSearchStore } from 'app/queue/utils';
import CorrespondenceTasksAdded from '../CorrespondenceTasksAdded';
import moment from 'moment';
import Pagination from 'app/components/Pagination/Pagination';
import Table from 'app/components/Table';
import { ExternalLinkIcon } from 'app/components/icons/ExternalLinkIcon';
import { COLORS } from 'app/constants/AppConstants';
import Checkbox from 'app/components/Checkbox';
import CorrespondencePaginationWrapper from 'app/queue/correspondence/CorrespondencePaginationWrapper';

const CorrespondenceDetails = (props) => {
  const dispatch = useDispatch();
  const correspondence = props.correspondence;
  const mailTasks = props.correspondence.mailTasks;

  const allCorrespondences = props.correspondence.all_correspondences;
  const [viewAllCorrespondence, setViewAllCorrespondence] = useState(false);
  const [currentPage, setCurrentPage] = useState(1);
  const totalPages = Math.ceil(allCorrespondences.length / 15);
  const startIndex = (currentPage * 15) - 15;
  const endIndex = (currentPage * 15);
  const priorMail = correspondence.prior_mail;
  const relatedCorrespondenceIds = props.correspondence.relatedCorrespondenceIds;

  priorMail.sort((first, second) => {
    const firstInRelated = relatedCorrespondenceIds.includes(first.id);
    const secondInRelated = relatedCorrespondenceIds.includes(second.id);

    if (firstInRelated && secondInRelated) {
      return new Date(second.vaDateOfReceipt) - new Date(first.vaDateOfReceipt);
    } else if (firstInRelated) {
      return -1;
    } else if (secondInRelated) {
      return -1;
    }

    return 1;
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
          const formattedDate = `${month}/${day}/${year}`;

          return formattedDate;
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

  const appealsResult = props.correspondence.appeals_information;
  const appeals = [];
  let filteredAppeals = [];
  let unfilteredAppeals = [];

  appealsResult.appeals.map((appeal) => {
    if (correspondence.correspondenceAppealIds?.includes(appeal.id)) {
      return filteredAppeals.push(appeal);
    }

    return unfilteredAppeals.push(appeal);
  });

  filteredAppeals = filteredAppeals.sort((leftAppeal, rightAppeal) => leftAppeal.id - rightAppeal.id);
  unfilteredAppeals = unfilteredAppeals.sort((leftAppeal, rightAppeal) => leftAppeal.id - rightAppeal.id);
  const sortedAppeals = filteredAppeals.concat(unfilteredAppeals);

  const searchStoreAppeal = prepareAppealForSearchStore(sortedAppeals);
  const appeall = searchStoreAppeal.appeals;
  const appealldetail = searchStoreAppeal.appealDetails;
  const hashKeys = Object.keys(appeall);

  hashKeys.map((key) => {
    const combinedHash = { ...appeall[key], ...appealldetail[key] };

    appeals.push(combinedHash);

    return appeals;
  });

  useEffect(() => {
    dispatch(loadCorrespondence(correspondence));
    dispatch(correspondenceInfo(correspondence));
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
          <h2>Existing Appeals</h2>
          <AppSegment filledBackground noMarginTop>
            <span>
              <a rel="noopener noreferrer"
                target="_blank"
                href={`/reader/appeal/${correspondence.veteranFileNumber}`}
                className="correspondence-details-view-documents">
              View veteran documents
                <div className="link-icon-spacing">
                  <ExternalLinkIcon color={COLORS.FOCUS_OUTLINE} />
                </div>
              </a>
            </span>

            <CaseListTable
              appeals={appeals}
              paginate="true"
              showCheckboxes
              taskRelatedAppealIds={props.correspondence.correspondenceAppealIds}
              disabled
              enableTopPagination
            />
          </AppSegment>
          {(props.correspondence.correspondenceAppeals.map((taskAdded) =>

            taskAdded.correspondencesAppealsTasks?.length > 0 && <CorrespondenceTasksAdded
              task_added={taskAdded}
              correspondence={props.correspondence}
              organizations={props.organizations}
              userCssId={props.userCssId}
            />
          )
          )}
        </div>
      </React.Fragment>
    );
  };
  const correspondenceAndAppealTaskComponents = <>
    {correspondenceTasks()}

    <section className="task-not-related-title">Tasks not related to an appeal</section>
    <div className="correspondence-case-timeline-container">
      <CorrespondenceCaseTimeline
        organizations={props.organizations}
        userCssId={props.userCssId}
        correspondence={props.correspondence}
        tasksToDisplay={props.correspondence.tasksUnrelatedToAppeal}
      />
    </div>
  </>;

  const correspondencePackageDetails = () => {
    return (
      <>
        <div className="correspondence-package-details">
          <h2 className="correspondence-h2">General Information</h2>
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
                  {props.correspondence.veteranFullName} ({props.correspondence.veteranFileNumber})
                </td>
                <td>{props.correspondence.correspondenceType}</td>
                <td>{props.correspondence.nod ? 'NOD' : 'Non-NOD'}</td>
                <td className="corr-table-borderless-last-item">
                  {moment(props.correspondence.vaDateOfReceipt).format('MM/DD/YYYY')}
                </td>
              </tr>
              <tr>
                <th colSpan={6} className="corr-table-borderless-first-item corr-table-borderless-last-item">
                  <strong>Notes</strong></th>
              </tr>
              <tr>
                <td colSpan={6} className="corr-table-borderless-first-item corr-table-borderless-last-item">
                  {props.correspondence.notes}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </>
    );
  };

  const correspondenceResponseLetters = () => {
    return (
      <>
        <div className="correspondence-package-details">
          <CorrespondenceResponseLetters
            letters={props.correspondenceResponseLetters}
          />
        </div>
      </>
    );
  };

  const getDocumentColumns = (correspondenceRow) => {
    return [
      {
        cellClass: 'checkbox-column',
        valueFunction: () => (
          <div className="checkbox-column-inline-style">
            <Checkbox
              name={correspondenceRow.id.toString()}
              id={correspondenceRow.id.toString()}
              hideLabel
              defaultValue={relatedCorrespondenceIds.some((el) => el === correspondenceRow.id)}
              disabled
            />
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
                rowObjects={priorMail}
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

  return (
    <>
      <AppSegment filledBackground extraClassNames="app-segment-cd-details">
        <div className="correspondence-details-header">
          <h1> {props.correspondence.veteranFullName} </h1>
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
        <td className="taskContainerStyling taskInformationTimelineContainerStyling"></td>
      </AppSegment>
    </>
  );
};

CorrespondenceDetails.propTypes = {
  loadCorrespondence: PropTypes.func,
  correspondence: PropTypes.object,
  organizations: PropTypes.array,
  userCssId: PropTypes.string,
  enableTopPagination: PropTypes.bool,
  correspondence_appeal_ids: PropTypes.bool,
  tasksUnrelatedToAppealEmpty: PropTypes.bool,
  correspondenceResponseLetters: PropTypes.array
};

const mapStateToProps = (state) => ({
  correspondenceInfo: state.correspondenceDetails.correspondenceInfo,
  tasksUnrelatedToAppealEmpty: state.correspondenceDetails.tasksUnrelatedToAppealEmpty,
});

const mapDispatchToProps = (dispatch) => (
  bindActionCreators({
    correspondenceInfo
  }, dispatch)
);

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(CorrespondenceDetails);

/* eslint-enable max-lines */
