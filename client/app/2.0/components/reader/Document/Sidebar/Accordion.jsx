// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import AccordionSection from 'app/components/AccordionSection';
import Alert from 'app/components/Alert';
import { Accordion } from 'app/components/Accordion';
import { COMMENT_ACCORDION_KEY } from 'app/reader/PdfViewer/actionTypes';

import Categories from 'components/reader/Document/Sidebar/Categories';
import Comments from 'components/reader/Document/Sidebar/Comments';
import DocumentInformation from 'components/reader/Document/Sidebar/DocumentInformation';
import IssueTags from 'components/reader/Document/Sidebar/IssueTags';
import WindowSlider from 'components/reader/Document/Sidebar/WindowSlider';

/**
 * Document Accordion Section component
 * @param {Object} props -- Contains details about the accordion sections
 */
export const DocumentAccordion = ({
  featureToggles,
  openSections,
  commentListRef,
  toggleAccordion,
  didLoadAppealFail,
  reload,
  ...props
}) => (
  <div className="cf-sidebar-accordion" id="cf-sidebar-accordion" ref={commentListRef}>
    {featureToggles.windowSlider && <WindowSlider />}
    <Accordion style="outline" onChange={toggleAccordion} activeKey={openSections}>
      <AccordionSection title="Document information">
        {didLoadAppealFail ? (
          <Alert type="error">
            Unable to retrieve claim details <br />
            Please <a href="#" onClick={reload}>refresh this page</a> or try again later.
          </Alert>
        ) : (
          <DocumentInformation {...props} />
        ) }
      </AccordionSection>
      <AccordionSection title="Categories">
        <Categories {...props} />
      </AccordionSection>
      <AccordionSection title="Issue tags">
        <IssueTags {...props} />
      </AccordionSection>
      <AccordionSection title={COMMENT_ACCORDION_KEY} id="comments-header">
        <Comments {...props} />
      </AccordionSection>
    </Accordion>
  </div>
);

DocumentAccordion.propTypes = {
  reload: PropTypes.func,
  didLoadAppealFail: PropTypes.bool,
  featureToggles: PropTypes.object,
  openSections: PropTypes.array,
  commentListRef: PropTypes.element,
  toggleAccordion: PropTypes.func,
  appeal: PropTypes.object,
  doc: PropTypes.object,
};
