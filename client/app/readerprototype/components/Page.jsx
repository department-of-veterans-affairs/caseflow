import PropTypes from 'prop-types';
import { css } from 'glamor';
import React, { useEffect, useRef } from 'react';
import reportWebVitals from '../util/ReportWebVitals';

const Page = ({ page, rotation = '0deg', renderItem, scale }) => {
  const canvasRef = useRef(null);
  // const hasReportedWebVitals = useRef(false);

  const viewport = page.getViewport({ scale: 1 });
  const wrapperStyle = css({
    rotate: rotation,
    transform: `scale(${scale / 100.0})`,
    padding: '10px',
  });

  useEffect(() => {
    if (canvasRef.current) {
      page.render({ canvasContext: canvasRef.current?.getContext('2d'), viewport });
      reportWebVitals(true, page.pageNumber, page._stats);
    }
  }, [canvasRef.current, viewport]);

  // useEffect(() => {
  //   if (!hasReportedWebVitals.current) {
  //     reportWebVitals(true, page.pageNumber);
  //     hasReportedWebVitals.current = true;
  //   }
  // }, [canvasRef.current]);

  return (
    <div id={`canvasWrapper-${page.pageNumber}`} className={`${wrapperStyle} prototype-canvas-wrapper`}>
      <canvas
        id={`canvas-${page.pageNumber}`}
        className="prototype-canvas"
        ref={canvasRef}
        height={viewport.height}
        width={viewport.width}
      />
      {renderItem &&
        renderItem({
          pageNumber: page.pageNumber,
          dimensions: {
            width: viewport?.width,
            height: viewport?.height,
          },
          rotation,
        })}
    </div>
  );
};

Page.propTypes = {
  page: PropTypes.object,
  rotation: PropTypes.string,
  renderItem: PropTypes.func,
  scale: PropTypes.number,
};

export default Page;
