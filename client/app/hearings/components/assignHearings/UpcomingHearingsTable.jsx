import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';

import { encodeQueryParams, getQueryParams } from '../../../util/QueryParamsUtil';
import ApiUtil from '../../../util/ApiUtil';
import QUEUE_CONFIG from '../../../../constants/QUEUE_CONFIG';
import { LOGO_COLORS } from '../../../constants/AppConstants';
import { AssignHearingsList } from './AssignHearingsList';
import LoadingScreen from '../../../components/LoadingScreen';

export const UpcomingHearingsTable = ({ selectedHearingDay, selectedRegionalOffice }) => {
  const [loading, setLoading] = useState(false);
  const [hearings, setHearings] = useState({});

  useEffect(() => {
    const currentQueryParams = getQueryParams(window.location.search);

    // Overwrite the current tab name in the query string.
    currentQueryParams[QUEUE_CONFIG.TAB_NAME_REQUEST_PARAM] =
      QUEUE_CONFIG.UNASSIGNED_TASKS_TAB_NAME;

    // This table doesn't use pagination, so the page param can be removed.
    delete currentQueryParams[QUEUE_CONFIG.PAGE_NUMBER_REQUEST_PARAM];

    window.history.replaceState('', '', encodeQueryParams(currentQueryParams));
  }, []);

  useEffect(() => {
    setLoading(true);
    ApiUtil.get(`/hearing_days/${selectedHearingDay.id}/hearings`).
      then((response) => {
        const resp = ApiUtil.convertToCamelCase(response?.body?.hearings);

        setHearings(resp);
        setLoading(false);
      });
  }, [selectedHearingDay]);

  return loading ? <LoadingScreen spinnerColor={LOGO_COLORS.QUEUE.ACCENT} /> : (
    <div>
      <Link to={`/schedule/docket/${selectedHearingDay.id}`}>
        {`View the Daily Docket for ${moment(selectedHearingDay.scheduledFor).format('M/DD/YYYY')}`}
      </Link>
      <AssignHearingsList
        hearings={Object.values(hearings)}
        hearingDay={selectedHearingDay}
        regionalOffice={selectedRegionalOffice}
      />
    </div>
  );
};

UpcomingHearingsTable.propTypes = {
  selectedHearingDay: PropTypes.shape({
    id: PropTypes.number,
    scheduledFor: PropTypes.string,
  }),

  // Selected Regional Office Key
  selectedRegionalOffice: PropTypes.string,
};

export default UpcomingHearingsTable;
