import React from 'react';
import PropTypes from 'prop-types';
import classnames from 'classnames';
import _ from 'lodash';

import Tooltip from './Tooltip';
import { DoubleArrow } from './RenderFunctions';
import { COLORS } from '../constants/AppConstants';
import { css, hover } from 'glamor';
import FilterIcon from './FilterIcon';
import DropdownFilter from './DropdownFilter';
import ListItemPicker from './ListItemPicker';
import ListItemPickerCheckbox from './ListItemPickerCheckbox';

/**
 * This component can be used to easily build tables.
 * The required props are:
 * - @columns {array[string]} array of objects that define the properties
 *   of the columns. Possible attributes for each column include:
 *   - @header {string|component} header cell value for the column
 *   - @align {sting} alignment of the column ("left", "right", or "center")
 *   - @valueFunction {function(rowObject)} function that takes `rowObject` as
 *     an argument and returns the value of the cell for that column.
 *   - @valueName {string} if valueFunction is not defined, cell value will use
 *     valueName to pull that attribute from the rowObject.
 *   - @footer {string} footer cell value for the column
 * - @rowObjects {array[object]} array of objects used to build the <tr/> rows
 * - @summary {string} table summary
 *
 * see StyleGuideTables.jsx for usage example.
 */
const helperClasses = {
  center: 'cf-txt-c',
  left: 'cf-txt-l',
  right: 'cf-txt-r'
};

const cellClasses = ({ align, cellClass }) => classnames([helperClasses[align], cellClass]);

const getColumns = (props) => {
  return _.isFunction(props.columns) ?
    props.columns(props.rowObject) : props.columns;
};

const HeaderRow = (props) => {
  const sortableHeaderStyle = css({ display: 'table-row' }, hover({ cursor: 'pointer' }));
  const sortArrowsStyle = css({
    display: 'table-cell',
    paddingLeft: '1rem',
    paddingTop: '0.3rem',
    verticalAlign: 'middle'
  });

  return <thead className={props.headerClassName}>
    <tr>
      {getColumns(props).map((column, columnNumber) => {
        let columnContent = <span>{column.header || ''}</span>;

        if (column.getSortValue) {
          const topColor = props.sortColIdx === columnNumber && !props.sortAscending ?
            COLORS.PRIMARY :
            COLORS.GREY_LIGHT;
          const botColor = props.sortColIdx === columnNumber && props.sortAscending ?
            COLORS.PRIMARY :
            COLORS.GREY_LIGHT;

          columnContent = <span {...sortableHeaderStyle} onClick={() => props.setSortOrder(columnNumber)}>
            <span>{column.header || ''}</span>
            <span {...sortArrowsStyle}><DoubleArrow topColor={topColor} bottomColor={botColor} /></span>
          </span>;
        }

        if (column.getFilterValues) {
          columnContent = <span><span>{column.header || ''}</span>
            <span><FilterIcon
              label={column.label}
              idPrefix={column.valueName}
              getRef={column.getFilterIconRef}
              selected={column.isDropdownFilterOpen || column.anyFiltersAreSet}
              handleActivate={column.toggleDropdownFilterVisibility} />

            {column.isDropdownFilterOpen &&
              <DropdownFilter
                name={column.valueName}
                isClearEnabled={column.anyFiltersAreSet}
                handleClose={column.toggleDropdownFilterVisibility}>
                { column.useCheckbox ?
                  <ListItemPickerCheckbox
                    options={column.getFilterValues}
                    setSelectedValue={column.setSelectedValue}
                    selected={column.checkSelectedValue} /> :
                  <ListItemPicker
                    options={column.getFilterValues}
                    setSelectedValue={column.setSelectedValue} />
                }
              </DropdownFilter>
            }
            </span>
          </span>;
        }

        return <th scope="col" key={columnNumber} className={cellClasses(column)} {...column?.sortProps}>
          { column.tooltip ?
            <Tooltip id={`tooltip-${columnNumber}`} text={column.tooltip}>{columnContent}</Tooltip> :
            <React.Fragment>{columnContent}</React.Fragment>
          }
        </th>;
      })}
    </tr>
  </thead>;
};

const getCellValue = (rowObject, rowId, column) => {
  if (column.valueFunction) {
    return column.valueFunction(rowObject, rowId);
  }
  if (column.valueName) {
    return rowObject[column.valueName];
  }

  return '';
};

const getCellSpan = (rowObject, column) => {
  if (column.span) {
    return column.span(rowObject);
  }

  return 1;
};

// todo: make these functional components?
class Row extends React.PureComponent {
  render() {
    const props = this.props;
    const rowId = props.footer ? 'footer' : props.rowId;
    const rowClassnameCondition = classnames(!props.footer && props.rowClassNames(props.rowObject));

    return <tr id={`table-row-${rowId}`} className={rowClassnameCondition}>
      {getColumns(props).
        filter((column) => getCellSpan(props.rowObject, column) > 0).
        map((column, columnNumber) =>
          <td
            key={columnNumber}
            className={cellClasses(column)}
            colSpan={getCellSpan(props.rowObject, column)}>
            {props.footer ?
              column.footer :
              getCellValue(props.rowObject, props.rowId, column)}
          </td>
        )}
    </tr>;
  }
}

class BodyRows extends React.PureComponent {
  render() {
    const { rowObjects, bodyClassName, columns, rowClassNames, tbodyRef, id, getKeyForRow, bodyStyling } = this.props;

    return <tbody className={bodyClassName} ref={tbodyRef} id={id} {...bodyStyling}>
      {rowObjects.map((object, rowNumber) => {
        const key = getKeyForRow(rowNumber, object);

        return <Row
          rowObject={object}
          columns={columns}
          rowClassNames={rowClassNames}
          key={key}
          rowId={key} />;
      }
      )}
    </tbody>;
  }
}

class FooterRow extends React.PureComponent {
  render() {
    const props = this.props;
    const hasFooters = _.some(props.columns, 'footer');

    return <tfoot>
      {hasFooters && <Row columns={props.columns} footer />}
    </tfoot>;
  }
}

export default class Table extends React.PureComponent {
  constructor(props) {
    super(props);

    const { defaultSort } = this.props;
    const state = {
      sortAscending: true,
      sortColIdx: null
    };

    if (defaultSort) {
      Object.assign(state, defaultSort);
    }

    this.state = state;
  }

  defaultRowClassNames = () => ''

  sortRowObjects = () => {
    const { rowObjects } = this.props;
    const {
      sortColIdx,
      sortAscending
    } = this.state;

    if (sortColIdx === null) {
      return rowObjects;
    }

    const builtColumns = getColumns(this.props);

    return _.orderBy(rowObjects,
      (row) => builtColumns[sortColIdx].getSortValue(row),
      sortAscending ? 'asc' : 'desc'
    );
  }

  render() {
    let {
      columns,
      summary,
      headerClassName = '',
      bodyClassName = '',
      rowClassNames = this.defaultRowClassNames,
      getKeyForRow,
      slowReRendersAreOk,
      tbodyId,
      tbodyRef,
      caption,
      id,
      styling,
      bodyStyling
    } = this.props;
    const rowObjects = this.sortRowObjects();

    let keyGetter = getKeyForRow;

    if (!getKeyForRow) {
      keyGetter = _.identity;
      if (!slowReRendersAreOk) {
        console.warn('<Table> props: one of `getKeyForRow` or `slowReRendersAreOk` props must be passed. ' +
          'To learn more about keys, see https://facebook.github.io/react/docs/lists-and-keys.html#keys');
      }
    }

    return <table
      id={id}
      className={`usa-table-borderless ${this.props.className ?? ''}`}
      summary={summary}
      {...styling} >

      { caption && <caption className="usa-sr-only">{ caption }</caption> }

      <HeaderRow
        columns={columns}
        headerClassName={headerClassName}
        setSortOrder={(colIdx, ascending = !this.state.sortAscending) => this.setState({
          sortColIdx: colIdx,
          sortAscending: ascending
        })}
        {...this.state} />
      <BodyRows
        id={tbodyId}
        tbodyRef={tbodyRef}
        columns={columns}
        getKeyForRow={keyGetter}
        rowObjects={rowObjects}
        bodyClassName={bodyClassName}
        rowClassNames={rowClassNames}
        bodyStyling={bodyStyling}
        {...this.state} />
      <FooterRow columns={columns} />
    </table>;
  }
}

HeaderRow.propTypes = {
  headerClassName: PropTypes.string,
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  setSortOrder: PropTypes.func,
  sortColIdx: PropTypes.number,
  sortAscending: PropTypes.bool
};

Row.propTypes = {
  footer: PropTypes.bool,
  rowId: PropTypes.number,
  rowClassNames: PropTypes.func,
  rowObject: PropTypes.object.isRequired
};

BodyRows.propTypes = {
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  bodyClassName: PropTypes.string,
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  rowClassNames: PropTypes.func,
  tbodyRef: PropTypes.func,
  id: PropTypes.string,
  getKeyForRow: PropTypes.func,
  bodyStyling: PropTypes.array
};

FooterRow.propTypes = {
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired
};

Table.propTypes = {
  tbodyId: PropTypes.string,
  tbodyRef: PropTypes.func,
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowClassNames: PropTypes.func,
  getKeyForRow: PropTypes.func,
  slowReRendersAreOk: PropTypes.bool,
  summary: PropTypes.string,
  headerClassName: PropTypes.string,
  className: PropTypes.string,
  caption: PropTypes.string,
  id: PropTypes.string,
  styling: PropTypes.object,
  defaultSort: PropTypes.shape({
    sortColIdx: PropTypes.number,
    sortAscending: PropTypes.bool
  }),
  bodyClassName: PropTypes.string,
  bodyStyling: PropTypes.array
};
