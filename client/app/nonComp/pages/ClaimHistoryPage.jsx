import React from 'react';
import { useSelector } from 'react-redux';
import NonCompLayout from '../components/NonCompLayout';
import IndividualClaimHistoryTable from '../components/IndividualClaimHistoryTable';
import Link from 'app/components/Link';
import styled from 'styled-components';

const LinkDiv = styled.div`
  display: inline-block;
  margin-top: 1rem;
`;

const ClaimHistoryPage = () => {

  const task = useSelector(
    (state) => state.nonComp.task
  );

  const returnLink = `../${task.id}`;

  return <div className="individual-claim-history">
    <LinkDiv> <Link to={returnLink}><b><u>&lt; Back to Decision Review</u></b></Link></LinkDiv>
    <NonCompLayout>
      <h1>{task.claimant.name}</h1>
      <IndividualClaimHistoryTable />
    </NonCompLayout>
  </div>;
};

export default ClaimHistoryPage;
