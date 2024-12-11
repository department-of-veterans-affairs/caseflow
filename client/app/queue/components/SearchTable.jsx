import React from 'react';
import { useDispatch } from 'react-redux';
import PropTypes from 'prop-types';
import QueueTable from '../../queue/QueueTable';
import RadioField from 'app/components/RadioField';
import { selectSavedSearch } from '../../nonComp/actions/savedSearchSlice';
import moment from 'moment';

export const SearchTable = ({ eventRows }) => {
  const dispatch = useDispatch();
  const onSavedSearchChange = (row) => {
    dispatch(selectSavedSearch(row));
  };

  const columns = [
    {
      valueFunction: (row) => <RadioField
        name="savedSearchRadioFieldGroup"
        label="Select search"
        options={[{ value: row.id.toString() }]}
        hideLabel
        onChange={() => onSavedSearchChange(row)}
        vertical
        optionsStyling={{ marginLeft: 5 }}
      />
    },
    { name: 'searchName',
      header: 'Search Name',
      getSortValue: (row) => row.name,
      valueFunction: (row) => row.name,
    },
    { name: 'savedDate',
      header: 'Saved Date',
      getSortValue: (row) => moment(row.createdAt).format('MM/DD/YYYY'),
      valueFunction: (row) => moment(row.createdAt).format('MM/DD/YYYY'),
    },
    { name: 'admin',
      header: 'Admin',
      getSortValue: (row) => `${row.user.fullName} (${row.user.cssId})`,
      valueFunction: (row) => `${row.user.fullName} (${row.user.cssId})`,
    },
    { name: 'description',
      header: 'Description',
      valueFunction: (row) => row.description
    }
  ];

  return (<QueueTable
    id="saved_search_table"
    columns={columns}
    rowObjects={eventRows}
    enablePagination
    getKeyForRow={(index) => index}
    defaultSort= {{
      sortColName: 'savedDate',
      sortAscending: false
    }}
  />);
};

SearchTable.propTypes = {
  eventRows: PropTypes.array,
  searchPageApiEndpoint: PropTypes.string,
};

export default SearchTable;
