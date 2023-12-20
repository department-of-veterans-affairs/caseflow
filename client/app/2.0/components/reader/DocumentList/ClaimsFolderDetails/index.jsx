// External Dependencies
import React from 'react';
import PropTypes from 'prop-types';
import { isEmpty } from 'lodash';

// Local Dependencies
import { Accordion } from 'app/components/Accordion';
import AccordionSection from 'app/components/AccordionSection';
import { AppealDetails } from 'components/reader/DocumentList/ClaimsFolderDetails/AppealDetails';
import { viewedParagraphStyles } from 'styles/reader/DocumentList/ClaimsFolderDetails';

/**
 * Claims Folder Details Component
 * @param {Object} props -- React props containing the appeal and documents
 */
export const ClaimsFolderDetails = ({ appeal, documents, docsCount }) => {
  // Set whether the appeal exists
  const noAppeal = isEmpty(appeal);

  // Set the Count of documents viewed
  const docsViewedCount = Object.keys(documents).filter((doc) => documents[doc].opened_by_current_user).length;

  return (
    <div>
      <div>
        {!noAppeal && <h1 className="cf-push-left">{appeal.veteran_full_name}'s Claims Folder</h1>}
        <p className="cf-push-right" {...viewedParagraphStyles}>
          You've viewed {docsViewedCount} out of {docsCount} documents
        </p>
      </div>
      <Accordion style="bordered" accordion={false} defaultActiveKey={['Claims Folder details']}>
        <AccordionSection
          id="claim-folder-details-accordion"
          className="usa-grid"
          disabled={noAppeal}
          title={noAppeal ? 'Loading...' : 'Claims folder details'}
        >
          {!noAppeal && <AppealDetails appeal={appeal} />}
        </AccordionSection>
      </Accordion>
    </div>
  );
};

ClaimsFolderDetails.propTypes = {
  appeal: PropTypes.object,
  documents: PropTypes.object,
  docsCount: PropTypes.number
};
