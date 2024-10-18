import React, { useEffect } from 'react';
import PropTypes from 'prop-types';

const CorrespondencePdfPage = (props) => {
  const { page, scale, rotation, canvasRefs, index, viewportRef } = props;

  useEffect(() => {
    const canvas = document.getElementById(`canvas-${page.pageNumber}`);
    const context = canvas.getContext('2d');
    const viewport = page.getViewport({
      scale,
      rotation,
    });

    canvas.width = viewport.width;
    canvas.height = viewport.height;
    viewportRef.current.height = viewport.height;
    viewportRef.current.width = viewport.width;

    const renderOptions = {
      canvasContext: context,
      viewport,
    };

    page.render(renderOptions);
  }, [scale, rotation, page]);

  return (
    <canvas
      id={`canvas-${page.pageNumber}`}
      className="canvasWrapper"
      ref={(ref) => (canvasRefs.current[index] = ref)} />
  );
};

CorrespondencePdfPage.propTypes = {
  page: PropTypes.object,
  scale: PropTypes.number,
  rotation: PropTypes.number,
  canvasRefs: PropTypes.object,
  index: PropTypes.number,
  viewportRef: PropTypes.object
};

export default CorrespondencePdfPage;
