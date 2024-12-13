import debounce from 'lodash/debounce';
import Mark from 'mark.js';
import PropTypes from 'prop-types';
import React, { useEffect, useRef } from 'react';
import { useDispatch, useSelector } from 'react-redux';
import Button from '../../components/Button';
import SearchBar from '../../components/SearchBar';
import { LeftChevronIcon } from '../../components/icons/LeftChevronIcon';
import { RightChevronIcon } from '../../components/icons/RightChevronIcon';
import { LOGO_COLORS } from '../../constants/AppConstants';
import {
  searchText,
  setSearchIndex,
  updateSearchIndexPage,
  updateSearchRelativeIndex
} from '../../reader/PdfSearch/PdfSearchActions';
import { getCurrentMatchIndex, getMatchesPerPageInFile, getTotalMatchesInFile } from '../../reader/selectors';

const currentPageIndexofMatch = (matchIndex, matchesPerPage) => {
  // get page, relative index of match at absolute index
  let cumulativeMatches = 0;

  if (Number.isNaN(matchIndex)) {
    return -1;
  }

  for (let matchesPerPageIndex = 0; matchesPerPageIndex < matchesPerPage.length; matchesPerPageIndex++) {
    if (matchIndex < cumulativeMatches + matchesPerPage[matchesPerPageIndex].matches) {
      const pageNumber = matchesPerPage[matchesPerPageIndex].pageIndex + 1;

      return { pageNumber, relativeIndex: matchIndex - cumulativeMatches };
    }

    cumulativeMatches += matchesPerPage[matchesPerPageIndex].matches;
  }

  return -1;
};
const scrollToPageIndexofMatch = (matchIndex, matchesPerPage, dispatch) => {
  const { pageNumber, relativeIndex } = currentPageIndexofMatch(matchIndex, matchesPerPage);

  if (pageNumber < 0 || typeof pageNumber === 'undefined') {
    return;
  }

  dispatch(updateSearchIndexPage(pageNumber));
  dispatch(updateSearchRelativeIndex(relativeIndex));
};

const ReaderSearchBar = ({ file }) => {
  const searchBarRef = useRef(null);
  const dispatch = useDispatch();
  const totalMatches = useSelector((state) => getTotalMatchesInFile(state, { file }));
  const matchesPerPage = useSelector((state) => getMatchesPerPageInFile(state, { file }));
  const foundIndex = useSelector((state) => getCurrentMatchIndex(state, { file }));
  const pdfContainer = document.getElementById('pdfContainer');

  window.markInstance = new Mark(pdfContainer);
  if (pdfContainer) {
    pdfContainer.className = 'prototype-mark';
  }

  const next = () => {
    const newIndex = (foundIndex + 1) % totalMatches;

    dispatch(setSearchIndex(newIndex));
  };

  const previous = () => {
    let newIndex = foundIndex - 1;

    if (newIndex < 0) {
      newIndex = totalMatches - 1;
    }
    dispatch(setSearchIndex(newIndex));
  };

  useEffect(() => {
    scrollToPageIndexofMatch(foundIndex, matchesPerPage, dispatch);
  }, [foundIndex]);

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
  }, [totalMatches, foundIndex]);

  // clean up on unmount
  useEffect(
    () => () => {
      dispatch(searchText(null));
      dispatch(setSearchIndex(0));

      window.markInstance.unmark();
    },
    []
  );

  const onChange = debounce((value) => {
    window.markInstance.unmark();
    dispatch(setSearchIndex(0));

    if (value === '') {
      dispatch(searchText(null));
    } else {
      dispatch(searchText(value));
    }
  }, 500);

  const index = totalMatches === 0 ? 0 : foundIndex + 1;
  const internalText = `${index} of ${totalMatches > 9999 ? 'many' : totalMatches}`;

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

ReaderSearchBar.propTypes = {
  file: PropTypes.string
};

export default ReaderSearchBar;
