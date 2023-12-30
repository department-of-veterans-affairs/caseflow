import React, { useState, useEffect } from 'react';
import { useSelector } from 'react-redux';
import {
  sectionSegmentStyling,
  sectionHeadingStyling } from 'app/queue/StickyNavContentArea';
import COPY from '../../../../COPY';

export const InactiveDataElements = (props) => {
  return (
    <div id="inactive-data-elements">
      <h2 {...sectionHeadingStyling}>
        <span>{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_TITLE}</span>
      </h2>
      <div {...sectionSegmentStyling}>
        <p className="cf-lead-paragraph">{COPY.CASE_DISTRIBUTION_STATIC_LEVERS_DESCRIPTION}</p>
      </div>
    </div>
  );
};

export default InactiveDataElements;
