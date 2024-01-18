import React from 'react';
import { useSelector } from 'react-redux';
import NonCompLayout from '../components/NonCompLayout';
import Link from 'app/components/Link';

const ClaimHistoryPage = () => {

  const task = useSelector(
    (state) => state.nonComp.task
  );

  const returnLink = `${task.tasks_url}/tasks/${task.id}`;

  return <>
    <Link href={returnLink}><b><u>&lt; Back to Decision Review</u></b></Link>
    <NonCompLayout>
      <h1>{task.claimant.name}</h1>
    </NonCompLayout>
  </>;
};

export default ClaimHistoryPage;
