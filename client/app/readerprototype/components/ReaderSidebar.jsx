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
import SideBarComments from '../../reader/SideBarComments';
import SideBarDocumentInformation from '../../reader/SideBarDocumentInformation';
import IssueTags from './IssueTags';


const ReaderSidebar = (doc, documents, hideSidebar, toggleSidebar) => {
  const [isKeyboardModalOpen, setIsKeyboardModalOpen] = useState(false);
  let comments = [];
  const hiddenSidebar = hideSidebar ? 'hidden-sidebar' : '';

  return (
    <div className="cf-sidebar-wrapper-prototype">
      <div className="cf-sidebar-header">
        <Button name="hide menu" classNames={['cf-pdf-button']} id="hide-menu-header" onClick={() => toggleSidebar()}>
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
          // onChange={onAccordionOpenOrClose()}
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
              doc={doc?.doc}
              documents={documents}
            />
          </AccordionSection>
          <AccordionSection title="Issue tags">
            <IssueTags doc={doc?.doc} />
          </AccordionSection>
          <AccordionSection title="Comments"
            id="comments-header"
          >
            <SideBarComments comments={comments} />
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
          // onClick={openKeyboardModal}
          classNames={['cf-btn-link']}
        />
        {isKeyboardModalOpen && (
          <div className="cf-modal-scroll">
            <Modal
              buttons={[
                {
                  classNames: ['usa-button', 'usa-button-secondary'],
                  name: 'Thanks, got it!',
                  // onClick: closeKeyboardModalFromButton
                },
              ]}
              // closeHandler={handleKeyboardModalClose}
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
      </div>
    </div>
  );
};

ReaderSidebar.propTypes = {
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    receivedAt: PropTypes.string,
    type: PropTypes.string,
  }),
  hideSidebar: PropTypes.bool,
  toggleSidebar: PropTypes.func,
};

export default ReaderSidebar;
