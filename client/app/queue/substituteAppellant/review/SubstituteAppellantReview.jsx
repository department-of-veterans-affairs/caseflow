import React from 'react';
import PropTypes from 'prop-types';

import AppSegment from '@department-of-veterans-affairs/caseflow-frontend-toolkit/components/AppSegment';
import {
  SUBSTITUTE_APPELLANT_REVIEW_TITLE,
  SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD,
} from 'app/../COPY';
import CheckoutButtons from 'app/queue/docketSwitch/grant/CheckoutButtons';
import { pageHeader } from '../styles';

export const SubstituteAppellantReview = ({ onBack, onCancel, onSubmit }) => {
  return (
    <>
      <AppSegment filledBackground>
        <section className={pageHeader}>
          <h1>{SUBSTITUTE_APPELLANT_REVIEW_TITLE}</h1>
          <div>{SUBSTITUTE_APPELLANT_REVIEW_SUBHEAD}</div>
        </section>
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
