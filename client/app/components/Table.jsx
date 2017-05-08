import React, { PropTypes } from 'react';
import classnames from 'classnames';
import _ from 'lodash';

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
export default class Table extends React.Component {
  render() {
    let {
      columns,
      rowObjects,
      summary,
      headerClassName = '',
      rowClassNames = () => '',
      id
    } = this.props;

    let alignmentClasses = {
      center: 'cf-txt-c',
      left: 'cf-txt-l',
      right: 'cf-txt-r'
    };

    let cellClasses = (column) => {
      return classnames([alignmentClasses[column.align], column.cellClass]);
    };

    let getColumns = (props) => {
      return _.isFunction(props.columns) ?
        props.columns(props.rowObject) : props.columns;
    };

    let HeaderRow = (props) => {
      return <thead className={headerClassName}>
        <tr>
          {getColumns(props).map((column, columnNumber) =>
            <th scope="col" key={columnNumber} className={cellClasses(column)}>
              {column.header || ''}
            </th>
          )}
        </tr>
      </thead>;
    };

    let getCellValue = (rowObject, rowNumber, column) => {
      if (column.valueFunction) {
        return column.valueFunction(rowObject, rowNumber);
      }
      if (column.valueName) {
        return rowObject[column.valueName];
      }

      return '';
    };

    let getCellSpan = (rowObject, column) => {
      if (column.span) {
        return column.span(rowObject);
      }

      return 1;
    };

    let Row = (props) => {
      let rowId = props.footer ? 'footer' : props.rowNumber;

      return <tr id={`table-row-${rowId}`} className={!props.footer && rowClassNames(props.rowObject)}>
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
    };

    let BodyRows = (props) => {
      return <tbody className={this.props.bodyClassName}>
        {props.rowObjects.map((object, rowNumber) =>
          <Row
            rowObject={object}
            columns={props.columns}
            rowNumber={rowNumber}
            key={rowNumber} />
        )}
      </tbody>;
    };

    let FooterRow = (props) => {
      let hasFooters = _.some(props.columns, (column) => column.footer);

      return <tfoot>
        {hasFooters && <Row columns={props.columns} footer={true}/>}
      </tfoot>;
    };

    return <table
              id={id}
              className={`usa-table-borderless cf-table-borderless ${this.props.className}`}
              summary={summary} >

        <HeaderRow columns={columns} />
        <BodyRows columns={columns} rowObjects={rowObjects} />
        <FooterRow columns={columns} />
    </table>;
  }
}

Table.propTypes = {
  columns: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.object),
    PropTypes.func]).isRequired,
  rowObjects: PropTypes.arrayOf(PropTypes.object).isRequired,
  rowClassNames: PropTypes.func,
  summary: PropTypes.string.isRequired,
  headerClassName: PropTypes.string,
  className: PropTypes.string,
  id: PropTypes.string
};
