import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import ApiUtil from '../../util/ApiUtil';

const loadOrganization = async (orgUrl) => {
  const { body: org } = await ApiUtil.get(`/organizations/${orgUrl}`);

  return org;
};

export const OrganizationDashboardView = ({ organization: orgUrl }) => {
  const [org, setOrg] = useState({});

  useEffect(() => {
    loadOrganization(orgUrl).then((res) => setOrg(res));
  }, [orgUrl]);

  return <AppSegment filledBackground>{org && <h1>{org.name} Dashboard</h1>}</AppSegment>;
};
OrganizationDashboardView.propTypes = {
  organization: PropTypes.string
};
