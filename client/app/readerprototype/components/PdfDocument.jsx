import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/assets/pdf.worker.min.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';
import DocumentLoadError from './DocumentLoadError';

const PdfDocument = ({ doc, rotateDeg, setNumPages, zoomLevel, onLoad }) => {
  const [isDocumentLoadError, setIsDocumentLoadError] = useState(false);
  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);

  const containerStyle = {
    width: '100%',
    height: '100%',
    overflow: 'auto',
    paddingTop: '10px',
    alignContent: 'start',
    justifyContent: 'center',
    gap: '5rem',
  };

  useEffect(() => {
    const getDocData = async () => {
      setPdfDoc(null);
      setPdfPages([]);
      onLoad(true);
      const requestOptions = {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      };
      const byteArr = await ApiUtil.get(doc.content_url, requestOptions).then((response) => {
        return response.body;
      });

      onLoad(false);
      const docProxy = await getDocument({ data: byteArr }).promise;

      if (docProxy) {
        setPdfDoc(docProxy);
        setNumPages(docProxy.numPages);
      }
    };

    getDocData().catch((error) => {
      console.error(`ERROR with getting doc data: ${error}`);
      setIsDocumentLoadError(true);
    });
  }, [doc.content_url]);

  useEffect(() => {
    const pageArray = [];

    if (!pdfDoc) {
      return;
    }
    const getPdfData = async () => {
      for (let i = 1; i <= pdfDoc.numPages; i++) {
        const page = await pdfDoc.getPage(i);

        pageArray.push(page);
      }
      setPdfPages(pageArray);
    };

    getPdfData();
  }, [pdfDoc]);

  return (
    <div id="pdfContainer" style={containerStyle}>
      {isDocumentLoadError && <DocumentLoadError doc={doc} />}
      {pdfPages.map((page, index) => (
        <Page
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`page-${index}`}
          renderItem={(childProps) => (
            <Layer documentId={doc.id} zoomLevel={zoomLevel} rotation={rotateDeg} {...childProps}>
              <TextLayer page={page} zoomLevel={zoomLevel} rotation={rotateDeg} />
            </Layer>
          )}
        />
      ))}
    </div>
  );
};

PdfDocument.propTypes = {
  doc: PropTypes.shape({
    content_url: PropTypes.string,
    filename: PropTypes.string,
    id: PropTypes.number,
    type: PropTypes.string,
  }),
  rotateDeg: PropTypes.string,
  setNumPages: PropTypes.func,
  zoomLevel: PropTypes.number,
  onLoad: PropTypes.func,
};

export default PdfDocument;
