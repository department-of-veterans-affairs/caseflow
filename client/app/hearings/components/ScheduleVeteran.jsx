import React from 'react';
import PropTypes from 'prop-types';
import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import { RegionalOfficeDropdown } from '../../components/DataDropdowns';

export const ScheduleVeteran = ({ appeal, hearing, ...props }) => {
  return (
    <AppSegment filledBackground >
      <RegionalOfficeDropdown
        options={props.roList}
        onChange={props.onChange}
        value={appeal.regionalOffice || hearing.regionalOffice}
        validateValueOnMount
      />
    </AppSegment>
  );
};

ScheduleVeteran.propTypes = {
  onChange: PropTypes.func.isRequired,
  appeal: PropTypes.object,
  hearing: PropTypes.object
};
