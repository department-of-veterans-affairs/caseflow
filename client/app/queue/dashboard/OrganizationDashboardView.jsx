import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
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

  return (
    <AppSegment filledBackground>
      {org && <h1>{org.name} Dashboard</h1>}
      {stats && <OrganizationStatistics statistics={stats} />}
    </AppSegment>
  );
};
OrganizationDashboardView.propTypes = {
  organization: PropTypes.string
};
