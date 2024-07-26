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

const CorrespondenceDetails = (props) => {
  const dispatch = useDispatch();
  const correspondence = props.correspondence;
  const mailTasks = props.correspondence.mailTasks;
  const appealsResult = props.correspondence.appeals_information;
  const appeals = [];
  const searchStoreAppeal = prepareAppealForSearchStore(appealsResult.appeals);
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
              aria-label={COPY.CORRESPONDENCE_DETAILS.COMPLETED_MAIL_TASKS}
            >
              {
                mailTasks.length > 0 ?
                  mailTasks.map((item, index) => (
                    <li key={index} aria-label={`Task ${index + 1}: ${item}`} >{item}</li>
                  )) :
                  <li aria-label={COPY.CORRESPONDENCE_DETAILS.NO_COMPLETED_MAIL_TASKS}>
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

  const tabList = [
    {
      disable: false,
      label: 'Correspondence and Appeal Tasks',
      page: correspondenceAndAppealTaskComponents
    },
    {
      disable: false,
      label: 'Package Details',
      page: 'Information about Package Details'
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
