
import React from 'react';
import Measure from 'react-measure';
import update from 'immutability-helper';
import _ from 'lodash';

const MAX_WIDTH = 225;
const MAX_ASSUMED_ROWS_FOR_ONE_TAG = 2;
const MAX_SHOWN_ROWS = 2;

const getTagsRowFormat = (widths) => {
  const arrWidths = _.values(widths);
  let rows = {};
  let rowNum = 1;

  for (let i = 0; i < arrWidths.length; i++) {
    if (arrWidths[i] > MAX_WIDTH) {
      // if a single tag width is larger than max width, assume
      // that the tag is taking up two rows.
      // this doesn't account for single tag that may take up more than
      // two rows.
      rows[rowNum] = [i];
      rows[rowNum + 1] = [i];
      rowNum += MAX_ASSUMED_ROWS_FOR_ONE_TAG;
    } else if ((arrWidths[i] + arrWidths[i + 1]) > MAX_WIDTH) {
      rows[rowNum] = [i];
      rowNum += 1;

    // if two elements alongside each other have combined less
    // than max width, this row can fit more than one tag
    } else if ((arrWidths[i] + arrWidths[i + 1]) < MAX_WIDTH) {
      let indx = i;
      let totalWidth = 0;
      let indices = [];

      // get all the tags this row can hold
      while (indx < arrWidths.length &&
        (totalWidth + arrWidths[indx]) < MAX_WIDTH) {
        totalWidth += arrWidths[indx];
        indices.push(indx);
        indx += 1;
      }

      rows[rowNum] = indices;
      rowNum += 1;

      // decrementing indx because it was incremented in the
      // while loop.
      i = indx - 1;

    // if tag is less than max width and no other tag can
    // fit in the same row.
    } else {
      rows[rowNum] = [i];
      rowNum += 1;
    }
  }

  return rows;
};

const getindicesToHide = (rows) => {
  let hiddenindices = [];

  _.forOwn(rows, (value, key) => {
    if (key > MAX_SHOWN_ROWS) {
      hiddenindices = _.union(hiddenindices, rows[key]);
    }
  });

  return hiddenindices;
};

export default class TagTableColumn extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      widths: {},
      showAllTags: false
    };
  }

  setHeight = (index, dimensions) => {
    this.setState((prevState) => {
      return update(prevState, {
        widths: { $merge: {
          [index]: dimensions.width
        } }
      });
    });
  }

  getShowMoreLink = () => {
    const tagText = this.state.showAllTags ? 'See Less...' : 'See More...';

    return <a className="see-more-link-toggle" href="#" onClick={(element) => {
      element.preventDefault();
      this.setState((prevState) => {
        return { showAllTags: !prevState.showAllTags };
      });
    }}>
      {tagText}
    </a>;
  };

  getTagClassName = (indices, index) => {
    if (this.state.showAllTags) {
      return 'document-list-issue-tag';
    }

    return _.includes(indices, index) ? 'hidden' : 'document-list-issue-tag';
  };

  render() {
    const {
      tags
    } = this.props;

    const rows = getTagsRowFormat(this.state.widths);
    let showMoreDiv = '';

    // if number of tag rows exceed max
    // get show more link
    if (_.size(rows) > MAX_SHOWN_ROWS) {
      showMoreDiv = this.getShowMoreLink();
    }

    let hiddenTagindices = getindicesToHide(rows);

    return <div className="document-list-issue-tags">
      {tags.map((tag, index) => {
        return <Measure
          onMeasure={(dimensions) => {
            this.setHeight(index, dimensions);
          }}
          key={index}
        >
          <div className={this.getTagClassName(hiddenTagindices, index)}>
            {`${tag.text}`}
          </div>
        </Measure>;
      })}
      <br/>{showMoreDiv}
    </div>;
  }
}
