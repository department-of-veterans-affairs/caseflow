/* eslint-disable camelcase */

import PropTypes from 'prop-types';
import React, { useState } from 'react';
import COPY from 'app/../COPY';
import Button from 'app/components/Button';
import EditDocumentTypeModal from '../component/EditDocumentTypeModal';
import CorrespondencePdfUI from '../pdfPreview/CorrespondencePdfUI';

export const CmpDocuments = (props) => {
  const { documents, isReadOnly } = props;

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

  const tableStyle = (index, document) => {
    if (selectedId === index) {
      return <td className="correspondence-document-table-data-filled"
        onClick={() => setCurrentDocument(index)}> {document?.document_title}
      </td>;
    }

    return <td className="correspondence-document-table-data-empty"
      onClick={() => setCurrentDocument(index)}> {document?.document_title}
    </td>;
  };

  return (
    <div>
      <h2> {COPY.DOCUMENT_PREVIEW} </h2>
      <div className="cmp-document-border">
        <div className="cmp-document-pagination-style"> {paginationText} </div>
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
                  {tableStyle(index, document)}
                  <td className="cf-txt-c">
                    <Button
                      disabled={isReadOnly}
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
  selectedId: PropTypes.number,
  isReadOnly: PropTypes.bool
};

export default CmpDocuments;
