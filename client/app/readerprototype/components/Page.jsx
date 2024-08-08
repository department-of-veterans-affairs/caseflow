import PropTypes from 'prop-types';
import React, { useEffect, useRef, useState } from 'react';

const Page = ({ page, rotation = '0deg', renderItem, scale }) => {
  const canvasRef = useRef(null);
  const [isRendering, setIsRendering] = useState(false);
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
    if (canvasRef.current && !isRendering) {
      setIsRendering(true);
      page
        .render({ canvasContext: canvasRef.current?.getContext('2d'), viewport })
        .promise.then(() => setIsRendering(false));
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
};

export default Page;
