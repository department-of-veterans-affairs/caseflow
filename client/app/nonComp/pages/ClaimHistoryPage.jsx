import React, { useEffect } from 'react';
import { useSelector, useDispatch } from 'react-redux';
import NonCompLayout from '../components/NonCompLayout';
import Link from 'app/components/Link';
import styled from 'styled-components';
import { fetchIndividualHistory } from '../actions/changeHistorySlice';

const LinkDiv = styled.div`
  display: inline-block;
  margin-top: 1rem;
`;

const ClaimHistoryPage = () => {
  const dispatch = useDispatch();
  const { businessLineUrl, task } = useSelector((state) => state.nonComp);

  const events = useSelector((state) => state.changeHistory.events);

  useEffect(() => {
    dispatch(fetchIndividualHistory({ organizationUrl: businessLineUrl, taskId: task.id }));
  }, []);

  const returnLink = `../${task.id}`;

  // eslint-disable-next-line no-console
  console.log(events);

  return <div className="individual-claim-history">
    <LinkDiv> <Link to={returnLink}><b><u>&lt; Back to Decision Review</u></b></Link></LinkDiv>
    <NonCompLayout>
      <h1>{task.claimant.name}</h1>

    </NonCompLayout>
  </div>;
};

export default ClaimHistoryPage;
