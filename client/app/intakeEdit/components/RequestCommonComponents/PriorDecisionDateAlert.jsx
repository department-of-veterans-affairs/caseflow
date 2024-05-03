import React from 'react';
import Alert from 'app/components/Alert';
import { css } from 'glamor';

const PriorDecisionDateAlert = () => {
  const messageStyling = css({
    fontSize: '17px !important',
  });

  return <Alert
    type="info"
    lowerMargin
    messageStyling={messageStyling}>
  Issues without decision dates cannot be added to this decision review.
 Please intake a new decision review for any issues without an identified prior decision date.</Alert>;

};

export default PriorDecisionDateAlert;
