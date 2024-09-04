import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';
import { ROTATION_DEGREES } from '../util/readerConstants';

// This Page component is expected to be used within a flexbox container. Flex doesn't notice when children are
// transformed (scaled and rotated). Where * is the flex container:
//      *|--------------|*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|              |*
//      *|--------------|*
//
// When rotated and scaled looks like this:
//      *                *
//      *                *
//      *                *
//      *    --------    *
//      *    |      |    *
//      *    ________    *
//      *                *
//      *                *
// We have to also change the dimensions of the container so that the flex reflows.
// When scaling, we multiply the height and width (via the getViewport call) by the scale.
// When rotating, we swap height and width of the container.
// The child is still centered in the container, so we must offset it put it back to the
// top / center of the container.
const Page = ({ page, rotation = ROTATION_DEGREES.ZERO, renderItem, scale, setRenderingMetrics }) => {
  const canvasRef = useRef(null);
  const wrapperRef = useRef(null);
  const scaleFraction = scale / 100;
  const reportedStats = useRef(false);
  const renderTaskRef = useRef(null);

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
    // removes offscreen canvas from rendering calculations to improve performance
    contentVisibility: 'auto',
  };

  useEffect(() => {
    if (canvasRef.current) {
      if (renderTaskRef.current) {
        // renderTaskRef.current.cancel();
        // Don't do anything
        // console.log('** Do not start render.');
      } else {
        const renderTask = page.render({ canvasContext: canvasRef.current?.getContext('2d'), viewport });

        renderTaskRef.current = renderTask;

        renderTask.promise.
          then(() => {
            if (page._stats && Array.isArray(page._stats.times)) {

              const renderingTimes = page._stats.times.find((time) => time.name === 'Rendering');

              if (!reportedStats.current) {
                setRenderingMetrics(renderingTimes.end - renderingTimes.start);
                reportedStats.current = true;
              }
            }
          }).
          catch(() => {
            // this catch is necessary to prevent the error: Cannot use the same canvas during multiple render operations
          });

        // return () => {
        //   if (renderTask) {
        //   // renderTask.cancel();
        //   // console.log('** Cancelled the rendering task.');
        //   }
        // };
      }
    }
  }, [canvasRef.current, viewport]);

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
