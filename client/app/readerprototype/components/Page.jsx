import PropTypes from 'prop-types';
import { css } from 'glamor';
import React, { useEffect, useRef } from 'react';

const Page = ({ page, rotation = '0deg', renderItem, scale }) => {
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
  const wrapperStyle = css({
    height: `${rotatedHeight}px`,
    width: `${rotatedWidth}px`,
    position: 'relative',
  });
  const canvasStyle = css({
    rotate: rotation,
    position: 'relative',
    top,
  });

  useEffect(() => {
    if (canvasRef.current) {
      page.render({ canvasContext: canvasRef.current?.getContext('2d'), viewport });
    }
  }, [canvasRef.current, viewport]);

  return (
    <div id={`canvasWrapper-${page.pageNumber}`} className={`${wrapperStyle} prototype-canvas-wrapper`}>
      <canvas
        id={`canvas-${page.pageNumber}`}
        className={`prototype-canvas ${canvasStyle}`}
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
