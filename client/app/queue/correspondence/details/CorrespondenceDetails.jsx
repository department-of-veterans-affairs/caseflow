import React, { useEffect } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import TabWindow from '../../../components/TabWindow';
import CopyTextButton from '../../../components/CopyTextButton';
import { loadCorrespondence } from '../correspondenceReducer/correspondenceActions';
import CorrespondenceCaseTimeline from '../CorrespondenceCaseTimeline';
// import { CaseTimeline } from '../../CaseTimeline';

const CorrespondenceDetails = (props) => {
  const dispatch = useDispatch();
  const correspondence = useSelector((state) => state.correspondence);

  useEffect(() => {
    dispatch(loadCorrespondence(correspondence));
  }, []);

  const correspondenceAndAppealTaskComponents = <>
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
      <AppSegment filledBackground>
        <div className="correspondence-details-header">
          <h1> {props.correspondence.veteranFullName} </h1>
          <div className="copy-id">
            <p>Veteran ID:  </p>
            <CopyTextButton
              label="copy-id"
              text={props.correspondence.veteranFileNumber}
            />
          </div>
          <p><a href="/under_construction">View all correspondence</a></p>
          <div></div>
          <p className="last-item"><b>Record status: </b> Pending</p>
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
  userCssId: PropTypes.string
};

export default CorrespondenceDetails;
