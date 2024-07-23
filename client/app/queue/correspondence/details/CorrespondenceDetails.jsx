import React, { useEffect, useState } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import PropTypes from 'prop-types';
import TabWindow from '../../../components/TabWindow';
import CopyTextButton from '../../../components/CopyTextButton';
import { loadCorrespondence } from '../correspondenceReducer/correspondenceActions';
import LoadingDataDisplay from '../../../components/LoadingDataDisplay';
import ApiUtil from '../../../util/ApiUtil';
import CaseListTable from 'app/queue/CaseListTable';
import { prepareAppealForSearchStore } from 'app/queue/utils';


const CorrespondenceDetails = (props) => {
  const dispatch = useDispatch();
  const correspondence = props.correspondence;
  const mailTasks = props.correspondence.mailTasks;

  const [appeals, setAppeals] = useState([]);

  useEffect(() => {
    dispatch(loadCorrespondence(correspondence));
  }, []);

  useEffect(() => {
    ApiUtil.get('/search', { query: { veteran_ids: correspondence.veteranId } }).
      then((response) => {
        let searchStoreAppeal = prepareAppealForSearchStore(response.body.appeals)
        let appeall = searchStoreAppeal.appeals
        let appealldetail = searchStoreAppeal.appealDetails
        let hashKeys = Object.keys(appeall);
        let appealsArray = []
        hashKeys.map((key) => {
         let combinedHash = {...appeall[key], ...appealldetail[key] }
         appealsArray.push(combinedHash)
        })
        setAppeals(appealsArray)
    });
  });

  const correspondenceTasks = () => {
    return (
      <React.Fragment>
        <div className="correspondence-mail-tasks">
          <h2>Completed Mail Tasks</h2>
          <AppSegment filledBackground noMarginTop>
            <ul className={`${mailTasks.length > 2 ? 'grid-list' : ''}`}>
              {
                mailTasks.length > 0 ?
                  mailTasks.map((item, index) => (
                    <li key={index}>{item}</li>
                  )) :
                  <li>No previously completed mail tasks prior to intake.</li>
              }
            </ul>
          </AppSegment>
        </div>
      </React.Fragment>
    );
  };

  const tabList = [
    {
      disable: false,
      label: 'Correspondence and Appeal Tasks',
      page: correspondenceTasks()
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

      </AppSegment>
    </>
  );
};

CorrespondenceDetails.propTypes = {
  loadCorrespondence: PropTypes.func,
  correspondence: PropTypes.object,
  loadCorrespondenceStatus: PropTypes.func,
  correspondenceStatus: PropTypes.object,
  correspondence_appeal_ids: PropTypes.bool
};

export default CorrespondenceDetails;
