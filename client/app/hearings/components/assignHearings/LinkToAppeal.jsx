import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import React from 'react';
import moment from 'moment';

const LinkToAppeal = ({ appealExternalId, hearingDay, regionalOffice, children }) => {
  const date = moment(hearingDay.scheduledFor).format('YYYY-MM-DD');
  const qs = `?hearingDate=${date}&regionalOffice=${regionalOffice}`;

  return (
    <Link
      name={appealExternalId}
      href={`/queue/appeals/${appealExternalId}/${qs}`}>
      {children}
    </Link>
  );
}

export default LinkToAppeal;
