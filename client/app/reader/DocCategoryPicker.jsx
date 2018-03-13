import React from 'react';
import PropTypes from 'prop-types';
import _ from 'lodash';
import * as Constants from './constants';
import Checkbox from '../components/Checkbox';
import { css } from 'glamor';

const categoryLabelStyling = css({
  display: 'flex',
  alignItems: 'flex-start',
  marginBottom: 0,
  paddingBottom: 0
});
const categoryNameStyling = css({
  lineHeight: 1,
  paddingLeft: '7px'
});

const CategorySelector = (props) => {
  const { category, categoryName, handleCategoryToggle, categoryToggleStates, allowReadOnly } = props;
  const toggleState = categoryToggleStates[categoryName] || false;
  const label = <div {...categoryLabelStyling}>
    {category.svg}
    <span {...categoryNameStyling}>{category.humanName}</span>
  </div>;

  const handleChange = (checked) => {
    handleCategoryToggle(categoryName, checked);
  };

  return <Checkbox name={categoryName} onChange={handleChange}
    label={label} value={toggleState} disabled={category.readOnly && allowReadOnly} />;
};

CategorySelector.propTypes = {
  allowReadOnly: PropTypes.bool,
  category: PropTypes.shape({
    humanName: PropTypes.string.isRequired,
    svg: PropTypes.element.isRequired,
    readOnly: PropTypes.bool
  }).isRequired,
  categoryToggleStates: PropTypes.object,
  categoryName: PropTypes.string.isRequired
};

const docCategoryPickerStyle = css(
  {
    listStyleType: 'none',
    paddingLeft: 0,
    paddingBottom: 0,
    '& li':
    {
      marginBottom: 0,
      '& .cf-form-checkboxes': {
        marginTop: 0,
        marginBottom: 0,
        '& label': {
          marginBottom: 0
        }
      }
    },
    '& li:last-child': {
      div: { marginBottom: 0 },
      '& .cf-form-checkboxes': { marginBottom: 0 }
    }
  }
);

const DocCategoryPicker = ({ categoryToggleStates, handleCategoryToggle, allowReadOnly,
  dropdownFilterViewListStyle, dropdownFilterViewListItemStyle }) => {

  return <ul {...docCategoryPickerStyle} {...dropdownFilterViewListStyle}>
    {
      _(Constants.documentCategories).
        toPairs().
        // eslint-disable-next-line no-unused-vars
        sortBy(([name, category]) => category.renderOrder).
        map(
          ([categoryName, category]) => <li key={categoryName} {...dropdownFilterViewListItemStyle}>
            <CategorySelector category={category}
              allowReadOnly={allowReadOnly}
              handleCategoryToggle={handleCategoryToggle}
              categoryName={categoryName} categoryToggleStates={categoryToggleStates} />
          </li>
        ).
        value()
    }
  </ul>;
};

DocCategoryPicker.defaultProps = {
  dropdownFilterViewListStyle: {},
  dropdownFilterViewListItemStyle: {}
};

DocCategoryPicker.propTypes = {
  handleCategoryToggle: PropTypes.func.isRequired,
  categoryToggleStates: PropTypes.object,
  allowReadOnly: PropTypes.bool,
  dropdownFilterViewListStyle: PropTypes.object,
  dropdownFilterViewListItemStyle: PropTypes.object
};

export default DocCategoryPicker;
