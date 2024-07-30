import React, { useEffect } from 'react';
import { useDispatch } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import TabWindow from '../../../components/TabWindow';
import CopyTextButton from '../../../components/CopyTextButton';
import { loadCorrespondence } from '../correspondenceReducer/correspondenceActions';
import CorrespondenceCaseTimeline from '../CorrespondenceCaseTimeline';
import COPY from '../../../../COPY';
import CaseListTable from 'app/queue/CaseListTable';
import { prepareAppealForSearchStore } from 'app/queue/utils';
import moment from 'moment';

const CorrespondenceDetails = (props) => {
  const dispatch = useDispatch();
  const correspondence = props.correspondence;
  const mailTasks = props.correspondence.mailTasks;
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
  }, []);

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
            <CaseListTable
              appeals={appeals}
              paginate="true"
              showCheckboxes
              taskRelatedAppealIds={props.correspondence.correspondenceAppealIds}
              disabled
              enableTopPagination
            />
          </AppSegment>
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
        correspondence={props.correspondence} />
    </div>
  </>;

  const correspondencePackageDetails = () => {
    return (
      <React.Fragment>
        <div className="correspondence-package-details">
          <h2 className="correspondence-h2">General Information</h2>
          <table className="corr-table-borderless gray-border">
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
      </React.Fragment>
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
      page: 'Information about Response Letters'
    },
    {
      disable: false,
      label: 'Associated Prior Mail',
      page: 'Information about Associated Prior Mail'
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
          <p><a href="/under_construction">View all correspondence</a></p>
          <div></div>
          <p className="last-item"><b>Record status: </b>{props.correspondence.status}</p>
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
  loadCorrespondenceStatus: PropTypes.func,
  correspondenceStatus: PropTypes.object,
  correspondence_appeal_ids: PropTypes.bool,
  enableTopPagination: PropTypes.bool
};

export default CorrespondenceDetails;
