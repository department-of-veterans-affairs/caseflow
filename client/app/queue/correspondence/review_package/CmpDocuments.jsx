/* eslint-disable camelcase */

import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import Button from 'app/components/Button';
import EditDocumentTypeModal from '../component/EditDocumentTypeModal';

const cmpDocumentStyling = css({
  marginTop: '2%'
});

const correspondenceStyling = css({
  border: '1px solid #dee2e6'
});

const paginationStyle = css({
  marginTop: '2%',
  marginLeft: '1.5%'
});

export const CmpDocuments = (props) => {
  const { documents } = props;

  const [selectedId, setSelectedId] = useState(0);

  const paginationText = `Viewing 1-${documents.length} out of ${documents.length} total documents`;

  const setCurrentDocument = (index) => {
    setSelectedId(index);
  };

  const [modalState, setModalState] = useState(false);
  const [documentName, setDocumentName] = useState('');
  const [saveButton, setsaveButton] = useState('false');

  const openModal = () => {
    setModalState(true);
  };
  const closeModal = () => {
    setModalState(false);
  };

  const saveButtonValue = () => {
    setsaveButton(false);
  };

  const OpenModalLink = (newValue) => (
    <Button linkStyling onClick={() => {
      setDocumentName(newValue);
      openModal();
    }} >
      <span>Edit</span>
    </Button>
  );

  OpenModalLink.propTypes = {
    documentName: PropTypes.string
  };

  return (
    <div {...cmpDocumentStyling} >
      <h2> {COPY.DOCUMENT_PREVIEW} </h2>
      <div {...correspondenceStyling}>
        <div {...paginationStyle}> {paginationText} </div>
        <table className="correspondence-document-table">
          <tbody>
            <tr>
              <th > Document Type </th>
              <th className="cf-txt-c"> Action </th>
            </tr>
          </tbody>
          {modalState &&
            <EditDocumentTypeModal
              onCancel={closeModal}
              onSave = {saveButtonValue}
              document={documentName}
            />
          }
          { documents?.map((document, index) => {
            return (
              <tbody key={index}>
                <tr>
                  <td style={{ background: selectedId === index ? '#0071bc' : 'white',
                    color: selectedId === index ? 'white' : '#0071bc' }}
                  onClick={() => setCurrentDocument(index)}> {document?.document_title}
                  </td>
                  <td className="cf-txt-c">
                    <OpenModalLink documentName = {document?.document_title} />
                  </td>
                </tr>
              </tbody>
            );
          })}
        </table>
      </div>
    </div>
  );
};

CmpDocuments.propTypes = {
  documents: PropTypes.array,
};

export default CmpDocuments;
