/* eslint-disable */
// REMOVE ABOVE LINE BEFORE CONTINUING WORK ON THIS FILE

import React from 'react';
import PropTypes from 'prop-types';

import { css } from 'glamor';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_REVIEW_TITLE,
  SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';

const sectionStyle = css({ marginBottom: '24px' });

export const SubstituteAppellantReview = ({ onBack, onCancel, onSubmit }) => {
  return (
    <>
      <AppSegment filledBackground>
        <h1>{SUBSTITUTE_APPELLANT_REVIEW_TITLE}</h1>
        <div {...sectionStyle}>{SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD}</div>
      </AppSegment>
      <div className="controls cf-app-segment">
        <CheckoutButtons
          onCancel={onCancel}
          onBack={onBack}
          onSubmit={onSubmit}
          submitText="Confirm"
        />
      </div>
    </>
  );
};
SubstituteAppellantReview.propTypes = {
  onBack: PropTypes.func,
  onCancel: PropTypes.func,
  onSubmit: PropTypes.func,
};
/* eslint-enable */
