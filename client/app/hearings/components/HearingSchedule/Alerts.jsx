import React from 'react';
import PropTypes from 'prop-types';
import UserAlerts from 'app/components/UserAlerts';
import Alert from 'app/components/Alert';
import { getAlert } from 'app/hearings/utils';

export const HearingScheduleAlerts = ({
  successfulHearingDayCreate,
  successfulHearingDayDelete,
  selectedHearingDay,
  invalidDates,
}) => {
  const alert = getAlert({
    successfulHearingDayCreate,
    successfulHearingDayDelete,
    selectedHearingDay,
  });

  return (
    <React.Fragment>
      <UserAlerts />
      {(successfulHearingDayCreate || successfulHearingDayDelete) && (
        <Alert type={alert.type} title={alert.title} scrollOnAlert={false}>{alert.message}</Alert>
      )}
      {invalidDates && <Alert type="error" title="Please enter valid dates." />}
    </React.Fragment>
  );
};

HearingScheduleAlerts.propTypes = {
  selectedHearingDay: PropTypes.string,
  successfulHearingDayCreate: PropTypes.string,
  successfulHearingDayDelete: PropTypes.string,
  invalidDates: PropTypes.bool
};
