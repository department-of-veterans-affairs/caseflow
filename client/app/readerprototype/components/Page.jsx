import PropTypes from 'prop-types';
import { css } from 'glamor';
import * as PDFJS from 'pdfjs-dist';
import React, { useEffect, useRef } from 'react';

const Page = ({ page, rotation = '0deg' }) => {
  const canvasRef = useRef(null);
  const textLayerRef = useRef(null);

  const viewport = page.getViewport({ scale: 1 });

  const textLayerStyle = css({
    width: `${viewport?.width}px`,
    height: `${viewport?.height}px`,
    transformOrigin: 'left top',
    opacity: 1,
    position: 'absolute',
    top: 0,
    left: 0,
  });
  const wrapperStyle = css({
    rotate: rotation,
  });

  useEffect(() => {
    if (canvasRef.current) page.render({ canvasContext: canvasRef.current?.getContext('2d'), viewport });
  }, [canvasRef.current, viewport]);

  useEffect(() => {
    const getPageText = async () => {
      const pageText = await page.getTextContent();

      PDFJS.renderTextLayer({
        textContent: pageText,
        container: textLayerRef.current,
        viewport,
        textDivs: [],
      });
    };

    if (textLayerRef.current) {
      getPageText();
    }
  }, [textLayerRef.current]);

  return (
    <div id={`canvasContainer-${page.pageNumber}`} className={`${wrapperStyle} canvas-wrapper-prototype`}>
      <canvas
        id={`canvas-${page.pageNumber}`}
        className="canvas-container-prototype"
        ref={canvasRef}
        height={viewport.height}
        width={viewport.width}
      />
      <div ref={textLayerRef} className={`cf-pdf-pdfjs-textLayer ${textLayerStyle}`} />
    </div>
  );
};

Page.propTypes = {
  page: PropTypes.object,
  rotation: PropTypes.string,
};

export default Page;
