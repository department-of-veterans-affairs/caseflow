import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ApiUtil from '../../util/ApiUtil';

const fetchOrganization = async (orgUrl) => {
  const { body: org } = await ApiUtil.get(`/organizations/${orgUrl}`);

  return org;
};

const fetchTaskDataForOrg = async (orgId) => {
  const { body } = await ApiUtil.get('/tasks/visualization', { query: { organization_id: orgId } });

  return body.tasks;
};

export const OrganizationDashboardView = ({ organization: orgUrl }) => {
  const [org, setOrg] = useState({});
  const [taskData, setTaskData] = useState([]);

  useEffect(() => {
    const fetchData = async () => {
      const organization = await fetchOrganization(orgUrl);

      setOrg(organization);

      const res = await fetchTaskDataForOrg(organization.id);

      setTaskData(res);
    };

    fetchData();
  }, [orgUrl]);

  return <AppSegment filledBackground>{org && <h1>{org.name} Dashboard</h1>}</AppSegment>;
};
OrganizationDashboardView.propTypes = {
  organization: PropTypes.string
};
