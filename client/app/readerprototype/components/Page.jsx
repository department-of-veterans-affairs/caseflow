import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';

const Page = ({ page, rotation = '0deg', renderItem, scale, storeMetric }) => {
  const canvasRef = useRef(null);
  const scaleFraction = scale / 100;

  const viewport = page.getViewport({ scale: scaleFraction });
  const scaledHeight = viewport.height;
  const scaledWidth = viewport.width;
  let rotatedHeight = scaledHeight;
  let rotatedWidth = scaledWidth;
  let top = 0;
  let left = 0;
  const offset = (scaledHeight - scaledWidth) / 2;

  if (rotation.includes('90') || rotation.includes('270')) {
    rotatedHeight = scaledWidth;
    rotatedWidth = scaledHeight;
    top = `${offset * -1}px`;
    left = `${offset}px`;
  }
  const wrapperStyle = {
    height: `${rotatedHeight}px`,
    width: `${rotatedWidth}px`,
    position: 'relative',
  };
  const canvasStyle = {
    rotate: rotation,
    position: 'relative',
    top,
  };

  useEffect(() => {
    if (canvasRef.current) {
      const renderResult = page
        .render({ canvasContext: canvasRef.current?.getContext('2d'), viewport })
        .promise.catch(() => {
          // this catch is necessary to prevent the error: Cannot use the same canvas during multiple render operations
        });

      renderResult.finally(() => {
        storeMetric(page.pageNumber, page.stats.times);
      });
    }
  }, [canvasRef.current, viewport]);

  return (
    <div id={`canvasWrapper-${page.pageNumber}`} className="prototype-canvas-wrapper" style={wrapperStyle}>
      <canvas
        id={`canvas-${page.pageNumber}`}
        className="prototype-canvas"
        style={canvasStyle}
        ref={canvasRef}
        height={scaledHeight}
        width={scaledWidth}
      />
      {renderItem &&
        renderItem({
          pageNumber: page.pageNumber,
          dimensions: {
            height: scaledHeight,
            width: scaledWidth,
            offsetX: left,
            offsetY: top,
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
  storeMetric: PropTypes.func,
};

export default Page;
