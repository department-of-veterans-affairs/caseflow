import React from 'react';
import PropTypes from 'prop-types';
import COPY from 'app/../COPY';
import Alert from 'app/components/Alert';
import Link from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/Link';
import { css } from 'glamor';

const alertStyling = css({
  marginBottom: '2em',
  '& .usa-alert-text': { lineHeight: '1' },
});

const SubstituteAppellantInfoBanner = ({ appeal, substituteAppellant }) => {

  const substituteAppellantExists = appeal.substituteAppellant ? appeal.substituteAppellant : substituteAppellant;

  const substituteBannerMessage = <div>
    {COPY.SUBSTITUTE_APPELLANT_INFO_BANNER_DETAILS}
    <Link
      name="appeal-stream"
      to={`${substituteAppellantExists.target_appeal_uuid}`}>
      appeal stream.</Link>
  </div>;

  return (
    <div className="cf-sg-alert-slim">
      <Alert
        message={substituteBannerMessage}
        type="info"
        styling={alertStyling}
      />
      <br />
    </div>
  );
};

SubstituteAppellantInfoBanner.propTypes = {
  appeal: PropTypes.object.isRequired,
  substituteAppellant: PropTypes.object
};

export default SubstituteAppellantInfoBanner;
