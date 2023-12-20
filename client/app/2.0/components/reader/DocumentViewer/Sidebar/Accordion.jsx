// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';

// Internal Dependencies
import AccordionSection from 'app/components/AccordionSection';
import Alert from 'app/components/Alert';
import { Accordion } from 'app/components/Accordion';
import { COMMENT_ACCORDION_KEY } from 'app/reader/PdfViewer/actionTypes';

import { SidebarCategories } from 'components/reader/DocumentViewer/Sidebar/Categories';
import { SidebarComments } from 'components/reader/DocumentViewer/Sidebar/Comments';
import { DocumentInformation } from 'components/reader/DocumentViewer/Sidebar/DocumentInformation';
import { IssueTags } from 'components/reader/DocumentViewer/Sidebar/IssueTags';
import { WindowSlider } from 'components/shared/WindowSlider';

/**
 * Document Accordion Section component
 * @param {Object} props -- Contains details about the accordion sections
 */
export const SidebarAccordion = ({
  featureToggles,
  openSections,
  commentListRef,
  toggleAccordion,
  didLoadAppealFail,
  reload,
  ...props
}) => (
  <div className="cf-sidebar-accordion" id="cf-sidebar-accordion" ref={commentListRef}>
    {featureToggles.windowSlider && <WindowSlider {...props} />}
    <Accordion style="outline" onChange={toggleAccordion} activeKey={openSections}>
      <AccordionSection title="Document information">
        {didLoadAppealFail ? (
          <Alert type="error">
            Unable to retrieve claim details <br />
            Please <a href="#" onClick={reload}>refresh this page</a> or try again later.
          </Alert>
        ) : (
          <DocumentInformation {...props} />
        )}
      </AccordionSection>
      <AccordionSection title="Categories">
        <SidebarCategories {...props} />
      </AccordionSection>
      <AccordionSection title="Issue tags">
        <IssueTags {...props} />
      </AccordionSection>
      <AccordionSection title={COMMENT_ACCORDION_KEY} id="comments-header">
        <SidebarComments {...props} />
      </AccordionSection>
    </Accordion>
  </div>
);

SidebarAccordion.propTypes = {
  reload: PropTypes.func,
  didLoadAppealFail: PropTypes.bool,
  featureToggles: PropTypes.object,
  openSections: PropTypes.array,
  commentListRef: PropTypes.element,
  toggleAccordion: PropTypes.func,
  appeal: PropTypes.object,
  doc: PropTypes.object,
};
