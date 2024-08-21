import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';

const Page = ({ page, rotation = '0deg', renderItem, scale }) => {
  const canvasRef = useRef(null);
  const wrapperRef = useRef(null);
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
    backgroundColor: 'white',
  };
  let canvasStyle = {
    rotate: rotation,
    position: 'relative',
    top,
    contentVisibility: 'auto',
  };

  useEffect(() => {
    if (canvasRef.current) {
      page.render({ canvasContext: canvasRef.current?.getContext('2d'), viewport }).promise.catch(() => {
        // this catch is necessary to prevent the error: Cannot use the same canvas during multiple render operations
      });
    }
  }, [canvasRef.current, viewport]);

  // useEffect(() => {
  //   const observer = new IntersectionObserver(
  //     ([entry]) => {
  //       canvasStyle = { ...canvasStyle, display: entry.isIntersecting ? 'inline-block' : 'none' };
  //     },
  //     {
  //       root: document.getElementById('pdfContainer'),
  //       rootMargin: `${scaledHeight * 10}px`, // show 10 rows of pages before and after
  //       threshold: 0, // any of the target is visible
  //     }
  //   );

  //   if (wrapperRef.current) {
  //     observer.observe(wrapperRef.current);
  //   }

  //   // Clean up the observer
  //   return () => {
  //     if (wrapperRef.current) {
  //       observer.unobserve(wrapperRef.current);
  //     }
  //   };
  // }, [wrapperRef.current]);

  return (
    <div
      id={`canvasWrapper-${page.pageNumber}`}
      className="prototype-canvas-wrapper"
      style={wrapperStyle}
      ref={wrapperRef}
    >
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
