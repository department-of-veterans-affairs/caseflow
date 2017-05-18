import React, { PropTypes } from 'react';
import classnames from 'classnames';
import _ from 'lodash';
import {PerfDebugPureComponent} from '../util/PerfDebug';
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
const alignmentClasses = {
  center: 'cf-txt-c',
  left: 'cf-txt-l',
  right: 'cf-txt-r'
};

const cellClasses = ({ align, cellClass }) => classnames([alignmentClasses[align], cellClass]);

const getColumns = (props) => {
  return _.isFunction(props.columns) ?
    props.columns(props.rowObject) : props.columns;
};

const HeaderRow = (props) => {
  return <thead className={props.headerClassName}>
    <tr>
      {getColumns(props).map((column, columnNumber) =>
        <th scope="col" key={columnNumber} className={cellClasses(column)}>
          {column.header || ''}
        </th>
      )}
    </tr>
  </thead>;
};

const getCellValue = (rowObject, rowNumber, column) => {
  if (column.valueFunction) {
    return column.valueFunction(rowObject, rowNumber);
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

class Row extends PerfDebugPureComponent {
  render() {
    const props = this.props;
    const rowId = props.footer ? 'footer' : props.rowNumber;

    return <tr id={`table-row-${rowId}`} className={!props.footer && props.rowClassNames(props.rowObject)}>
      {getColumns(props).map((column, columnNumber) =>
        <td
          key={columnNumber}
          className={cellClasses(column)}
          colSpan={getCellSpan(props.rowObject, column)}>
          {props.footer ?
            column.footer :
            getCellValue(props.rowObject, props.rowNumber, column)}
        </td>
      )}
    </tr>;
  }
}

class BodyRows extends React.PureComponent {
  render() {
    const { rowObjects, bodyClassName, columns, rowClassNames, tbodyRef, id, getKeyForRow } = this.props;
    const keyGetter = getKeyForRow || _.identity;

    return <tbody className={bodyClassName} ref={tbodyRef} id={id}>
      {rowObjects.map((object, rowNumber) =>
        <Row
          rowObject={object}
          columns={columns}
          rowClassNames={rowClassNames}
          key={keyGetter(rowNumber, object)} />
      )}
    </tbody>;
  }
}

class FooterRow extends React.PureComponent {
  render() {
    const props = this.props;
    const hasFooters = _.some(props.columns, 'footer');

    return <tfoot>
      {hasFooters && <Row columns={props.columns} footer={true}/>}
    </tfoot>;
  }
}

export default class Table extends React.PureComponent {
  defaultRowClassNames = () => ''

  render() {
    let {
      columns,
      rowObjects,
      summary,
      headerClassName = '',
      bodyClassName = '',
      rowClassNames = this.defaultRowClassNames,
      getKeyForRow,
      tbodyId,
      tbodyRef,
      caption,
      id
    } = this.props;

    return <table
              id={id}
              className={`usa-table-borderless cf-table-borderless ${this.props.className}`}
              summary={summary} >

        { caption && <caption className="usa-sr-only">{ caption }</caption> }

        <HeaderRow columns={columns} headerClassName={headerClassName}/>
        <BodyRows
          id={tbodyId}
          tbodyRef={tbodyRef}
          columns={columns}
          getKeyForRow={getKeyForRow}
          rowObjects={rowObjects}
          bodyClassName={bodyClassName}
          rowClassNames={rowClassNames} />
        <FooterRow columns={columns} />
    </table>;
  }
}

Table.propTypes = {
  tbodyId: PropTypes.string,
  tbodyRef: PropTypes.func,
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowClassNames: PropTypes.func,
  summary: PropTypes.string.isRequired,
  headerClassName: PropTypes.string,
  className: PropTypes.string,
  caption: PropTypes.string,
  id: PropTypes.string
};
