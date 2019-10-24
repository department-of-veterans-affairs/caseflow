import React, { useEffect, useState } from 'react';
import { countBy } from 'lodash';
import moment from 'moment';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import CompletedTaskChart from './CompletedTaskChart';
import ApiUtil from '../../util/ApiUtil';
import { OrganizationStatistics } from './OrganizationStatistics';

const fetchOrganization = async (orgUrl) => {
  const { body: org } = await ApiUtil.get(`/organizations/${orgUrl}`);

  return org;
};

const fetchTaskDataForOrg = async (orgId) => {
  const { body } = await ApiUtil.get('/tasks/visualization', { query: { organization_id: orgId } });

  return body;
};

export const OrganizationDashboardView = ({ organization: orgUrl }) => {
  const [org, setOrg] = useState({});
  const [taskData, setTaskData] = useState([]);
  const [stats, setStats] = useState({});

  useEffect(() => {
    const fetchData = async () => {
      const organization = await fetchOrganization(orgUrl);

      setOrg(organization);

      const { tasks, statistics } = await fetchTaskDataForOrg(organization.id);

      setTaskData(tasks);
      setStats(statistics);
    };

    fetchData();
  }, [orgUrl]);

  const tasks = taskData.filter((task) => task.closed_at);

  let data = {};

  tasks.forEach((task) => {
    const date = moment(task.closed_at).format('YYYY-MM-DD');

    if (!data[date]) {
      data[date] = { x: new Date(date).toString(),
        y: 0 };
    }
    data[date].y += 1;
  });

  data = Object.values(data);
  const chartData = {
    id: 'Caseflow',
    data
  };

  return (
    <AppSegment filledBackground>
      {org && <h1>{org.name} Dashboard</h1>}
      {stats && <OrganizationStatistics statistics={stats} />}
      <div style={{ marginTop: '4rem' }}>{chartData && <CompletedTaskChart data={[chartData]} />}</div>
    </AppSegment>
  );
};
OrganizationDashboardView.propTypes = {
  organization: PropTypes.string
};
