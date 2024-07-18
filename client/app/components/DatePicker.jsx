import React, { useEffect, useState } from 'react';
import PropTypes from 'prop-types';
import { css } from 'glamor';

const datePickerStyle = css({
  position: 'relative',
});

const iconStyle = css({
  padding: '0.5em',
  display: 'table-cell',
  background: '#EEE',
  width: '15px',
  height: '15px',
  cursor: 'pointer',
  left: '10px',
  fontSize: '15px',
  position: 'relative',
});

const menuStyle = css({
  position: 'absolute',
  background: 'white',
  right: 0,
  top: '35px',
  width: '200px',
  height: '200px',
  border: '1px solid #CCC',
  padding: '1rem'
});

export const DatePicker = (props) => {
  const [open, setOpen] = useState(false);
  const [rootElement, setRootElement] = useState(null);

  const {
    onChange
  } = props;

  const toggleDropdown = () => setOpen(!open);

  const onGlobalClick = (event) => {
    if (rootElement && !rootElement.contains(event.target)) {
      setOpen(false);
    }
  };

  useEffect(() => {
    document.addEventListener('click', onGlobalClick, true);

    return () => {
      document.removeEventListener('click', onGlobalClick);
    };
  }, []);

  return (
    <span {...datePickerStyle} ref={(rootElem) => {
      setRootElement(rootElem);
    }}>
      <div {...iconStyle} onClick={toggleDropdown}>C</div>
      {open &&
      <div {...menuStyle}>
        <div>Date picker...</div>
        <div><button onClick={onChange}>Test</button></div>
      </div>
      }
    </span>
  );
};

DatePicker.propTypes = {
  onChange: PropTypes.func,
};

export default DatePicker;
