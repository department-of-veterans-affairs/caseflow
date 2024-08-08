import PropTypes from 'prop-types';
import React, { useState } from 'react';

import { Accordion } from '../../components/Accordion';
import AccordionSection from '../../components/AccordionSection';
import Button from '../../components/Button';
import Modal from '../../components/Modal';
import Table from '../../components/Table';

import { KeyboardIcon } from '../../components/icons/KeyboardIcon';
import {
  categoryColumns,
  categoryInstructions,
  commentColumns,
  commentInstructions,
  documentsColumns,
  documentsInstructions,
  searchColumns,
  searchInstructions,
} from '../../reader/PdfKeyboardInfo';

import SideBarCategories from '../../reader/SideBarCategories';
import Comments from './Comments';
import SideBarDocumentInformation from '../../reader/SideBarDocumentInformation';
import IssueTags from './IssueTags';
import { useDispatch } from 'react-redux';
import { setOpenedAccordionSections } from '../../reader/PdfViewer/PdfViewerActions';

const ReaderSidebar = ({
  // appeal,
  doc,
  documents,
  toggleSideBar,
}) => {
  const [isKeyboardModalOpen, setIsKeyboardModalOpen] = useState(false);
  const dispatch = useDispatch();

  const onAccordionOpenOrClose = (openedSections) => dispatch(setOpenedAccordionSections(openedSections, []));

  return (
    <nav id="prototype-sidebar">
      <div className="cf-sidebar-header">
        <Button name="hide menu"
          classNames={['cf-pdf-button']}
          id="hide-menu-header"
          onClick={() => toggleSideBar()}
        >
          <h2 className="cf-non-stylized-header">
            Hide menu <i className="fa fa-chevron-right" aria-hidden="true" />
          </h2>
        </Button>
      </div>

      <div
        className="cf-sidebar-accordion"
        id="cf-sidebar-accordion"
        // ref={(commentListElement) => {
        //   commentListElement = commentListElement;
        // }}
      >
        <Accordion
          style="outline"
          onChange={onAccordionOpenOrClose}
          // activeKey={props.openedAccordionSections}
        >
          <AccordionSection title="Document information">
            <SideBarDocumentInformation
              // appeal={appeal}
              doc={doc}
            />
          </AccordionSection>
          <AccordionSection title="Categories">
            <SideBarCategories
              doc={doc}
              documents={documents}
            />
          </AccordionSection>
          <AccordionSection title="Issue tags">
            <IssueTags doc={doc} />
          </AccordionSection>
          <AccordionSection title="Comments" id="comments-header">
            <Comments documentId={doc.id} />
          </AccordionSection>
        </Accordion>
      </div>

      <div className="cf-keyboard-shortcuts">
        <Button
          id="cf-open-keyboard-modal"
          name={
            <span>
              <KeyboardIcon />
              &nbsp; View keyboard shortcuts
            </span>
          }
          onClick={() => setIsKeyboardModalOpen(true)}
          classNames={['cf-btn-link']}
        />
      </div>
      {isKeyboardModalOpen && (
        <div className="cf-modal-scroll">
          <Modal
            buttons={[
              {
                classNames: ['usa-button', 'usa-button-secondary'],
                name: 'Thanks, got it!',
                onClick: () => setIsKeyboardModalOpen(false),
              },
            ]}
            closeHandler={() => setIsKeyboardModalOpen(false)}
            title="Keyboard shortcuts"
            noDivider
            id="cf-keyboard-modal"
          >
            <div className="cf-keyboard-modal-scroll">
              <Table
                columns={documentsColumns}
                rowObjects={documentsInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table"
              />
              <Table
                columns={searchColumns}
                rowObjects={searchInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table"
              />
              <Table
                columns={commentColumns}
                rowObjects={commentInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table"
              />
              <Table
                columns={categoryColumns}
                rowObjects={categoryInstructions}
                slowReRendersAreOk
                className="cf-keyboard-modal-table"
              />
            </div>
          </Modal>
        </div>
      )}
    </nav>
  );
};

ReaderSidebar.propTypes = {
  appeal: PropTypes.object,
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    receivedAt: PropTypes.string,
    type: PropTypes.string,
  }),
  documents: PropTypes.object,
  showSideBar: PropTypes.bool,
  toggleSideBar: PropTypes.func,
};

export default ReaderSidebar;
