import React from 'react';
import PropTypes from 'prop-types';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import moment from 'moment';

export const FnodBanner = ({ appeal }) => {
  const formattedDeathDate = moment(appeal.date_of_death).format('MM/DD/YYYY');
  const fnodBannerMessage = <div>
    <strong>Source:</strong> SSA |
    <strong> Date of Death:</strong> {formattedDeathDate} |
    <strong> Veteran Name:</strong> {appeal.veteranFullName}
  </div>;

  return (
    <div>
      <Alert
        message={fnodBannerMessage}
        title={COPY.CASE_DETAILS_FNOD_BANNER_TITLE}
        type="info"
      />
      <br />
    </div>
  );
};

FnodBanner.propTypes = {
  appeal: PropTypes.object.isRequired
};
