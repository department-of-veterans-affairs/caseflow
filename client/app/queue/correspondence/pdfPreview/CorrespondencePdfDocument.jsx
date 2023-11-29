import React, { useEffect, useMemo, useRef } from 'react';
import * as pdfjs from 'pdfjs-dist';
import pdfjsWorker from 'pdfjs-dist/build/pdf.worker.entry';
import { v4 as uuidv4 } from 'uuid';

pdfjs.GlobalWorkerOptions.workerSrc = pdfjsWorker;

const CorrespondencePdfDocument = (props) => {
  const {
    scale,
    pdfPageProxies,
    canvasRefs,
    currentPage,
    setCurrentPage,
    viewport,
    gridRef,
    pdfDocProxy,
    scrollViewRef
  } = props;



  const handleScroll = () => {
    const scrolledHeight = scrollViewRef.current.scrollTop;
    const pageOffset = Math.floor(scrolledHeight / viewport.height);
    const pageNumber = pageOffset + 1;

    if (currentPage !== pageNumber) {
      console.log(currentPage)
      console.log(pageNumber)
      console.log(scrolledHeight)
      setCurrentPage(pageNumber)
    }
  };

  const generatePdfPages = useMemo(() => pdfPageProxies.map((page, index) => {
    return (
      <CorrespondencePdfPage
        key={uuidv4()}
        uuid={uuidv4()}
        canvasRefs={canvasRefs}
        page={page}
        index={index}
        scale={scale}
        viewportState={viewport}
      />
    );
  }, [pdfPageProxies]));

  return (
    <div className="cf-pdf-preview-scrollview" ref={scrollViewRef} onScroll={handleScroll}>
      <div className="cf-pdf-preview-grid" ref={gridRef}>
        { generatePdfPages }
      </div>
    </div>
  );
};

const CorrespondencePdfPage = (props) => {
  const { page, scale, canvasRefs, uuid, index, viewportState } = props;

  useEffect(() => {
    const canvas = document.getElementById(`canvas-${page.pageNumber}`);
    const context = canvas.getContext('2d');
    const viewport = page.getViewport({ scale });

    canvas.width = viewport.width;
    canvas.height = viewport.height;
    viewportState.height = viewport.height;
    viewportState.width = viewport.width;

    const renderOptions = {
      canvasContext: context,
      viewport,
    };

    page.render(renderOptions);

  }, [scale]);

  return (
    <canvas id={`canvas-${page.pageNumber}`} className={`canvasWrapper ${uuid}`} ref={(ref) => (canvasRefs.current[index] = ref)} />
  );
};

export default CorrespondencePdfDocument;
