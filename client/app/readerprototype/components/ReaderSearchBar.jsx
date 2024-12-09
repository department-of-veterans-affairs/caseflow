import Mark from 'mark.js';
import React, { useEffect, useRef, useState } from 'react';
import Button from '../../components/Button';
import SearchBar from '../../components/SearchBar';
import { LeftChevronIcon } from '../../components/icons/LeftChevronIcon';
import { RightChevronIcon } from '../../components/icons/RightChevronIcon';
import { LOGO_COLORS } from '../../constants/AppConstants';

const ReaderSearchBar = () => {
  const [foundCount, setFoundCount] = useState(0);
  const [foundIndex, setFoundIndex] = useState(0);
  const searchBarRef = useRef(null);

  const pdfContainer = document.getElementById('pdfContainer');
  const markInstance = new Mark(pdfContainer);

  if (pdfContainer) {
    pdfContainer.className = 'prototype-mark';
  }

  const highlightMarkAtIndex = (selectedIndex = 0) => {
    const marks = pdfContainer.getElementsByTagName('mark');

    marks.forEach((mark, index) => {
      mark.classList.remove('highlighted');
      if (index === selectedIndex) {
        mark.classList.add('highlighted');
        mark.scrollIntoView({
          block: 'center',
        });
      }
    });
  };

  const next = () => {
    const newIndex = (foundIndex + 1) % foundCount;

    highlightMarkAtIndex(newIndex);
    setFoundIndex(newIndex);
  };

  const previous = () => {
    let newIndex = foundIndex - 1;

    if (newIndex < 0) {
      newIndex = foundCount - 1;
    }

    highlightMarkAtIndex(newIndex);
    setFoundIndex(newIndex);
  };

  // set focus upon mount
  useEffect(() => {
    searchBarRef.current?.setInputFocus();
  }, []);

  // handle keyboard control of search results
  useEffect(() => {
    const keyHandler = (event) => {
      const metaKey = navigator.appVersion.includes('Win') ? 'ctrlKey' : 'metaKey';

      if (event[metaKey] && event.code === 'KeyG') {
        event.preventDefault();
        if (event.shiftKey) {
          previous();
        } else {
          next();
        }
      }

      if (event.key === 'Enter') {
        next();
      }
    };

    window.addEventListener('keydown', keyHandler);

    // clean up event listener on unmount
    return () => window.removeEventListener('keydown', keyHandler);
  }, [foundCount, foundIndex]);

  // clean up on unmount
  useEffect(
    () => () => {
      markInstance.unmark({
        done: () => setFoundCount(0),
      });
    },
    []
  );

  const onChange = (value) => {
    setFoundIndex(0);

    if (value === '') {
      markInstance.unmark({
        done: () => setFoundCount(0),
      });
    } else {
      markInstance.unmark({
        done: () => {
          markInstance.mark(value, {
            separateWordSearch: false,
            done: (count) => {
              setFoundCount(count);
              highlightMarkAtIndex(0);
            },
          });
        },
      });
    }
  };

  const index = foundCount === 0 ? 0 : foundIndex + 1;
  const internalText = `${index} of ${foundCount > 9999 ? 'many' : foundCount}`;

  return (
    <div className="cf-search-bar" style={{ hidden: false }}>
      <SearchBar
        ref={searchBarRef}
        isSearchAhead
        size="small"
        id="search-ahead"
        placeholder="Type to search..."
        onChange={onChange}
        internalText={internalText}
        loading={false}
        spinnerColor={LOGO_COLORS.READER.ACCENT}
      />
      <Button classNames={['cf-increment-search-match', 'cf-prev-match']} onClick={previous}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}>
          <LeftChevronIcon />
          <span className="usa-sr-only">Previous Match</span>
        </div>
      </Button>
      <Button classNames={['cf-increment-search-match', 'cf-next-match']} onClick={next}>
        <div style={{ transform: 'translateY(5px) translateX(-0.5rem)' }}>
          <RightChevronIcon />
          <span className="usa-sr-only">Next Match</span>
        </div>
      </Button>
    </div>
  );
};

export default ReaderSearchBar;
