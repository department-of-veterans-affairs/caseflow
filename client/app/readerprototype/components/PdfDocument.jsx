import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import Layer from './Comments/Layer';

import { GlobalWorkerOptions, getDocument } from 'pdfjs-dist';
GlobalWorkerOptions.workerSrc = '/assets/pdf.worker.min.js';

import ApiUtil from '../../util/ApiUtil';
import Page from './Page';
import TextLayer from './TextLayer';

const PdfDocument = ({ fileUrl, rotateDeg, setNumPages, zoomLevel, documentId }) => {
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
      const requestOptions = {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer',
      };
      const byteArr = await ApiUtil.get(fileUrl, requestOptions).then((response) => {
        return response.body;
      });
      const docProxy = await getDocument({ data: byteArr }).promise;

      if (docProxy) {
        setPdfDoc(docProxy);
        setNumPages(docProxy.numPages);
      }
    };

    getDocData();
  }, [fileUrl]);

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
      {pdfPages.map((page, index) => (
        <Page
          scale={zoomLevel}
          page={page}
          rotation={rotateDeg}
          key={`page-${index}`}
          renderItem={(childProps) => (
            <Layer documentId={documentId} zoomLevel={zoomLevel} rotation={rotateDeg} {...childProps}>
              <TextLayer page={page} zoomLevel={zoomLevel} rotation={rotateDeg} />
            </Layer>
          )}
        />
      ))}
    </div>
  );
};

PdfDocument.propTypes = {
  fileUrl: PropTypes.string,
  rotateDeg: PropTypes.string,
  setNumPages: PropTypes.func,
  zoomLevel: PropTypes.number,
  documentId: PropTypes.number,
};

export default PdfDocument;
