import React, { useEffect, useState } from 'react';
import { countBy } from 'lodash';
import moment from 'moment'
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import CompletedTaskChart from './CompletedTaskChart'
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

  const tasks = taskData.filter(task => task["closed_at"])

  let data = {}

  tasks.forEach((task) => {
    const date = moment(task.closed_at).format('YYYY-MM-DD')
    if (!data[date]) data[date] = {x: (new Date(date)).toString(), y: 0}
    data[date].y++;
  })

  data = Object.values(data)
  let chartData = {
    "id": "Caseflow",
    "data": data
  }
  return <AppSegment filledBackground>{org && <h1>{org.name} Dashboard</h1>} <CompletedTaskChart data={[chartData]}/></AppSegment>;
};
OrganizationDashboardView.propTypes = {
  organization: PropTypes.string
};
