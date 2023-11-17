import PropTypes from 'prop-types';
import React, { useEffect } from 'react';
import { connect, useDispatch, useSelector } from 'react-redux';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';
import { COLORS } from '@department-of-veterans-affairs/caseflow-frontend-toolkit/util/StyleConstants';
import faker from 'faker';
import ISSUE_CATEGORIES from 'constants/ISSUE_CATEGORIES';
import BENEFIT_TYPES from 'constants/BENEFIT_TYPES';
import QueueTable from '../../queue/QueueTable';

import { dateTimeColumn, userColumn, activityColumn, detailsColumn } from 'app/nonComp/util/ChangeHistoryColumns';
import { uniqueId } from 'lodash';
import { fetchClaimEvents } from '../actions/changeHistorySlice';

const clearingDivStyling = css({
  borderBottom: `1px solid ${COLORS.GREY_LIGHT}`,
  clear: 'both'
});

// This should probably use existing css styles instead of this
// Probably cf-app-segment but it's not setup to work that way
const grayBorder = css({
  border: `1px solid ${COLORS.GREY_LIGHT}`,
  background: COLORS.WHITE,
  padding: '40px'
});

const generateFakeData = () => {
  const eventTypes = [
    'Added Decision Date',
    'Added Issue',
    'Add Issue - No Decision Date',
    'Claim Created',
    'Claim Closed',
    'Claim Status - Incomplete',
    'Claim Status - In Progress',
    'Completed Disposition',
    'Withdrew Issue',
    'Remove Issue'
  ];
  const benefitType = BENEFIT_TYPES.vha;
  const issueTypes = ISSUE_CATEGORIES.vha;
  const dispositions = [
    'Blank',
    'Granted',
    'Denied',
    'Dismissed',
    'DTA Error',
    'Withdrawn',
  ];
  const fakeData = {
    uniqueId: uniqueId(),
    eventType: faker.random.arrayElement(eventTypes),
    eventDate: faker.date.past().toISOString(),
    eventUser: faker.name.findName(),
    details: {
      benefitType,
      issueType: faker.random.arrayElement(issueTypes),
      issueDescription: faker.lorem.sentence(),
      decisionDate: faker.date.past().toISOString(),
      disposition: faker.random.arrayElement(dispositions),
      decisionDescription: faker.lorem.sentence(),
      withdrawlRequestDate: faker.date.past().toISOString(),
    }
  };

  return fakeData;
};

const ClaimHistoryGenerator = (props) => {
  const { businessLineUrl, task } = props;

  const dispatch = useDispatch();

  const events = useSelector((state) => state.changeHistory.events);

  useEffect(() => {
    dispatch(fetchClaimEvents({ taskID: task.id, businessLineUrl }));
  }, []);

  // Generate a list of 10 fake data
  // const fakeJsonData = Array.from({ length: 20 }, generateFakeData);

  // const changeHistoryColumns = [
  //   dateTimeColumn(), userColumn(fakeJsonData), activityColumn(fakeJsonData), detailsColumn()
  // ];

  const changeHistoryColumns = [
    dateTimeColumn(), userColumn(events), activityColumn(events), detailsColumn()
  ];

  // Print the generated data
  // fakeJsonData.forEach((data) => console.log(data));

  console.log(events);

  return <>
    <Link to={`/${businessLineUrl}/tasks/${task.id}`}> &lt; Back to Decision Review </Link>
    {/* <div {...grayBorder} className="cf-app-segment"> */}
    <div>
      <section className="cf-app-segment cf-app-segment--alt">
        <div>
          <h1>{task.claimant.name}</h1>
          <div {...clearingDivStyling} />
          <QueueTable
            columns={changeHistoryColumns}
            rowObjects={events}
            // rowObjects={fakeJsonData}
            getKeyForRow={(_rowNumber, event) => event.id}
            defaultSort={{ sortColIdx: 0 }}
            enablePagination
          />
        </div>
      </section>
    </div>
  </>;
};

ClaimHistoryGenerator.propTypes = {
  task: PropTypes.shape({
    id: PropTypes.number,
    claimant: PropTypes.object,
    type: PropTypes.string,
    created_at: PropTypes.string
  }),
  businessLine: PropTypes.string,
  history: PropTypes.shape({
    push: PropTypes.func
  }),
  businessLineUrl: PropTypes.string
};

// TODO: Trim this down to what we actually need. Might even just use selectors instead of connect
const ClaimHistoryPage = connect(
  (state) => ({
    appeal: state.nonComp.appeal,
    businessLine: state.nonComp.businessLine,
    businessLineUrl: state.nonComp.businessLineUrl,
    businessLineConfig: state.nonComp.businessLineConfig,
    task: state.nonComp.task,
    decisionIssuesStatus: state.nonComp.decisionIssuesStatus
  })
)(ClaimHistoryGenerator);

export default ClaimHistoryPage;
