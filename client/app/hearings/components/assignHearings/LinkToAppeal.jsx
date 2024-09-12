import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import PropTypes from 'prop-types';
import React from 'react';
import moment from 'moment';

const LinkToAppeal = ({ appealExternalId, hearingDay, regionalOffice, children, id = '' }) => {
  const date = moment(hearingDay?.scheduledFor).format('YYYY-MM-DD');
  const qs = `?hearingDate=${date}&regionalOffice=${regionalOffice}`;

  return (
    <Link
      name={appealExternalId + id}
      href={`/queue/appeals/${appealExternalId}/${qs}`}>
      {children}
    </Link>
  );
};

LinkToAppeal.propTypes = {
  appealExternalId: PropTypes.string,
  id: PropTypes.string,
  children: PropTypes.node,
  hearingDay: PropTypes.shape({
    scheduledFor: PropTypes.string
  }),
  regionalOffice: PropTypes.string
};

export default LinkToAppeal;
