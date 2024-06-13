import { css } from 'glamor';
import * as PDFJS from 'pdfjs-dist';

export const renderPage = async (pdfPage) => {
  const pdfContainer = document.getElementById('pdfContainer');
  const canvasWrapper = document.createElement('div');

  canvasWrapper.setAttribute('id', `canvasContainer-${pdfPage.pageNumber}`);
  canvasWrapper.className = 'canvas-wrapper-prototype';
  pdfContainer.appendChild(canvasWrapper);

  const canvas = document.createElement('canvas');
  const textLayer = document.createElement('div');

  canvas.setAttribute('id', `canvas-${pdfPage.pageNumber}`);
  canvas.className = 'canvas-container-prototype';
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

  textLayer.className = `cf-pdf-pdfjs-textLayer ${textLayerStyle}`;

  PDFJS.renderTextLayer({
    textContent: pageText,
    container: textLayer,
    viewport,
    textDivs: []
  });
};

export const renderPageBatch = (pdfPages, startIndex, endIndex) => {
  for (let i = startIndex; i < endIndex; i++) {
    renderPage(pdfPages[i]);
  }
};

export const rotatePages = (rotateDeg) => {
  const pages = document.getElementsByClassName('canvas-wrapper-prototype');

  pages.forEach((page) => {
    page.style = `rotate: ${rotateDeg}`;
  });
};
