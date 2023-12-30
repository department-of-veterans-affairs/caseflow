import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import {
  sectionSegmentStyling,
  sectionHeadingStyling } from 'app/queue/StickyNavContentArea';
import COPY from '../../../../COPY';

export const ChangeHistory = (props) => {
  return (
    <div id="case-distribution-history">
      <h2 {...sectionHeadingStyling}>
        <span>{COPY.CASE_DISTRIBUTION_HISTORY_TITLE}</span>
      </h2>
      <div {...sectionSegmentStyling}>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_HISTORY_DESCRIPTION}</p>
      </div>
    </div>
  );
};

export default ChangeHistory;
