/* eslint-disable camelcase */

import { css } from 'glamor';
import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import Button from 'app/components/Button';
import EditDocumentTypeModal from '../component/EditDocumentTypeModal';
import CorrespondencePdfUI from '../pdfPreview/CorrespondencePdfUI';

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

  const openModal = () => {
    setModalState(true);
  };
  const closeModal = () => {
    setModalState(false);
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
              modalState={modalState}
              setModalState={setModalState}
              onCancel={closeModal}
              document={documents[selectedId]}
              indexDoc={selectedId}
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
                    <Button
                      linkStyling
                      onClick={() => {
                        setCurrentDocument(index);
                        openModal();
                      }}>
                      <span>Edit</span>
                    </Button>
                  </td>
                </tr>
              </tbody>
            );
          })}
        </table>
      </div>
      <CorrespondencePdfUI documents={documents} selectedId={selectedId} />
    </div>
  );
};

CmpDocuments.propTypes = {
  documents: PropTypes.array,
  setSelectedId: PropTypes.func,
  selectedId: PropTypes.number
};

export default CmpDocuments;
