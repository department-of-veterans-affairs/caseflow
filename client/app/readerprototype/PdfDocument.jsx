
import React, { useEffect } from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';

import * as PDFJS from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';
PDFJS.GlobalWorkerOptions.workerSrc = pdfjsWorker;

import ApiUtil from '../util/ApiUtil';

const PdfDocument = (doc) => {

  useEffect(() => {
    const setPdfPages = () => {
      const requestOptions = {
        cache: true,
        withCredentials: true,
        timeout: true,
        responseType: 'arraybuffer'
      };

      ApiUtil.get(doc.file, requestOptions).
        then((response) => {

          return PDFJS.getDocument({ data: response.body }).promise;
        }).
        then((pdfDocumentProxy) => {
          const promises = _.range(0, pdfDocumentProxy?.numPages).map((index) => {

            return pdfDocumentProxy.getPage((index + 1));
          });

          return Promise.all(promises);
        }).
        then((pdfPageProxies) => {
          pdfPageProxies.forEach((page) => {
            const viewport = page.getViewport({ scale: 1.0 });

            let pdfContainer = document.getElementById('pdfContainer');
            let canvas = document.createElement('canvas');

            canvas.setAttribute('id', `canvas-${page.pageNumber}`);
            canvas.className = 'canvasWrapper';
            pdfContainer.appendChild(canvas);

            const canvasContext = canvas.getContext('2d');

            canvas.height = viewport.height;
            canvas.width = viewport.width;

            const renderContext = {
              canvasContext,
              viewport
            };

            const renderTask = page.render(renderContext);

            renderTask.promise.then(() => {
              console.log('Page rendered');
            });
          });
        }).
        catch((error) => {
          console.error(error);
        });
    };

    if (doc) {
      setPdfPages();
    }
  }, [doc]);

  return (
    <div
      style={{ height: '100%', overflow: 'auto' }}
      id = "pdfContainer">
    </div>
  );
};

PdfDocument.propTypes = {
  doc: PropTypes.object
};

export default PdfDocument;
