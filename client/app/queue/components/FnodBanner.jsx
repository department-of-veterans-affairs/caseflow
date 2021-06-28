import React from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import { formatDateStr } from 'app/util/DateUtil';

const FnodBanner = ({ appeal }) => {
  const formattedDeathDate = formatDateStr(appeal.veteranDateOfDeath);
  const fnodBannerInfoPadding = css({
    padding: '5px',
  });
  const fnodBannerMessage = <div>
    <strong>Source:</strong> {COPY.FNOD_SOURCE} <span {...fnodBannerInfoPadding}>|</span>
    <strong> Date of Death:</strong> {formattedDeathDate} <span {...fnodBannerInfoPadding}>|</span>
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

export default FnodBanner;
