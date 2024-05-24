import React, { useState } from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import { css } from 'glamor';
import classNames from 'classnames';

import { Accordion } from '../components/Accordion';
import AccordionSection from '../components/AccordionSection';
import Button from '../components/Button';
import Modal from '../components/Modal';
import SideBarCategories from '../reader/SideBarCategories';
import SideBarComments from '../reader/SideBarComments';
import SideBarDocumentInformation from '../reader/SideBarDocumentInformation';
import SideBarIssueTags from '../reader/SideBarIssueTags';
import Table from '../components/Table';
import WindowSlider from '../reader/WindowSlider';
import { KeyboardIcon } from '../components/icons/KeyboardIcon';
import { commentColumns, commentInstructions, documentsColumns,
  documentsInstructions, searchColumns, searchInstructions,
  categoryColumns, categoryInstructions } from '../reader//PdfKeyboardInfo';

const sideBarSmall = '250px';
const sideBarLarge = '380px';

const sidebarClass = classNames(
  'cf-sidebar-wrapper',
  // { 'hidden-sidebar': this.props.hidePdfSidebar }
);

const sidebarWrapper = css({
  width: '28%',
  minWidth: sideBarSmall,
  maxWidth: sideBarLarge,
  '@media(max-width: 920px)': { width: sideBarSmall },
  '@media(min-width: 1240px)': { width: sideBarLarge }
});

const ReaderSidebar = (doc) => {
  const [isModalOpen, setIsModalOpen] = useState(false);

  return <div className={sidebarClass} {...sidebarWrapper}>
    <div className="cf-sidebar-header">
      <Button
        name="hide menu"
        classNames={['cf-pdf-button']}
        id="hide-menu-header"
        // onClick={props.togglePdfSidebar}
      >
        <h2 className="cf-non-stylized-header">
          Hide menu <i className="fa fa-chevron-right" aria-hidden="true"></i>
        </h2>
      </Button>
    </div>
    <div
      className="cf-sidebar-accordion"
      id="cf-sidebar-accordion"
      // ref={(commentListElement) => {
      //   this.commentListElement = commentListElement;
      // }}
    >
      {/* { this.props.featureToggles.windowSlider && <WindowSlider /> } */}
      <Accordion style="outline"
        // onChange={this.onAccordionOpenOrClose}
        // activeKey={this.props.openedAccordionSections}
      >
        <AccordionSection title="Document information">
          <SideBarDocumentInformation
            // appeal={appeal}
            // doc={this.props.doc}
          />
        </AccordionSection>
        <AccordionSection title="Categories">
          <SideBarCategories doc={doc} />
        </AccordionSection>
        <AccordionSection title="Issue tags">
          <SideBarIssueTags
            doc={doc} />
        </AccordionSection>
        <AccordionSection
          // title={COMMENT_ACCORDION_KEY}
          id="comments-header">
          <SideBarComments
            // comments={comments}
          />
        </AccordionSection>
      </Accordion>
    </div>
    <div className="cf-keyboard-shortcuts">
      <Button
        id="cf-open-keyboard-modal"
        name={<span><KeyboardIcon />&nbsp; View keyboard shortcuts</span>}
        // onClick={this.openKeyboardModal}
        classNames={['cf-btn-link']}
      />
      { isModalOpen && <div className="cf-modal-scroll">
        <Modal
          buttons = {[
            { classNames: ['usa-button', 'usa-button-secondary'],
              name: 'Thanks, got it!',
              // onClick: this.closeKeyboardModalFromButton
            }
          ]}
          // closeHandler={this.handleKeyboardModalClose}
          title="Keyboard shortcuts"
          noDivider
          id="cf-keyboard-modal">
          <div className="cf-keyboard-modal-scroll">
            <Table
              columns={documentsColumns}
              rowObjects={documentsInstructions}
              slowReRendersAreOk
              className="cf-keyboard-modal-table" />
            <Table
              columns={searchColumns}
              rowObjects={searchInstructions}
              slowReRendersAreOk
              className="cf-keyboard-modal-table" />
            <Table
              columns={commentColumns}
              rowObjects={commentInstructions}
              slowReRendersAreOk
              className="cf-keyboard-modal-table" />
            <Table
              columns={categoryColumns}
              rowObjects={categoryInstructions}
              slowReRendersAreOk
              className="cf-keyboard-modal-table" />
          </div>
        </Modal>
      </div>
      }
    </div>
  </div>;
};

ReaderSidebar.propTypes = {
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
    receivedAt: PropTypes.string,
    type: PropTypes.string
  })
};

export default ReaderSidebar;
