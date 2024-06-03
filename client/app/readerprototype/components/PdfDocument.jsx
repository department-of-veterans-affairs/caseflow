import PropTypes from 'prop-types';
import React, { useEffect, useState } from 'react';
import { css } from 'glamor';


import * as PDFJS from 'pdfjs-dist';
import ApiUtil from '../../util/ApiUtil';

const renderPage = async (pdfPage) => {
  let pdfContainer = document.getElementById('pdfContainer');
  let canvasWrapper = document.createElement('div');

  canvasWrapper.setAttribute('id', `canvasContainer-${pdfPage.pageNumber}`);
  canvasWrapper.className = 'canvasWrapperPrototype';
  pdfContainer.appendChild(canvasWrapper);

  let canvas = document.createElement('canvas');
  const textLayer = document.createElement('div');

  canvas.setAttribute('id', `canvas-${pdfPage.pageNumber}`);
  canvas.className = 'canvasContainerPrototype';
  canvasWrapper.appendChild(canvas);
  canvasWrapper.appendChild(textLayer);

  const viewport = pdfPage.getViewport({ scale: 1 });
  const canvasContext = canvas.getContext('2d');

  canvas.height = viewport.height;
  canvas.width = viewport.width;
  pdfPage.render({ canvasContext, viewport });
  const pageText = await pdfPage.getTextContent();

  const textLayerStyle = css({
    width: `${viewport.width}px`,
    height: `${viewport.height}px`,
    transformOrigin: 'left top',
    opacity: 1,
    position: 'absolute',
    top: 0,
    left: 0
  });

  console.log(textLayerStyle)
  textLayer.className = `cf-pdf-pdfjs-textLayer ${textLayerStyle}`;

  PDFJS.renderTextLayer({
    textContent: pageText,
    container: textLayer,
    viewport,
    textDivs: []
  });
};

const renderPageBatch = (pdfPages, startIndex, endIndex) => {
  for (let i = startIndex; i < endIndex; i++) {
    renderPage(pdfPages[i]);
  }
};

const requestOptions = {
  cache: true,
  withCredentials: true,
  timeout: true,
  responseType: 'arraybuffer'
};

const PdfDocument = ({ fileUrl, zoomLevel }) => {

  const [pdfDoc, setPdfDoc] = useState(null);
  const [pdfPages, setPdfPages] = useState([]);

  useEffect(() => {
    const getDocData = async () => {

      const byteArr = await ApiUtil.get(fileUrl, requestOptions).
        then((response) => {
          return response.body;
        });
      const docProxy = await PDFJS.getDocument({ data: byteArr }).promise;

      if (docProxy) {
        setPdfDoc(docProxy);
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

  useEffect(() => {
    renderPageBatch(pdfPages, 0, pdfPages.length);
  }, [pdfPages]);

  return (
    <div
      style={{ height: '100%', overflow: 'auto', zoom: `${zoomLevel}%` }}
      id = "pdfContainer">
    </div>
  );
};

PdfDocument.propTypes = {
  fileUrl: PropTypes.string,
  zoomLevel: PropTypes.string,
  setDocumentPageCount: PropTypes.number
};

export default PdfDocument;
