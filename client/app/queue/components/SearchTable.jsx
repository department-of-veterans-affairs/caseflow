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
      getSortValue: (row) => row.attributes.name,
      valueFunction: (row) => row.attributes.name,
    },
    { name: 'savedDate',
      header: 'Saved Date',
      getSortValue: (row) => moment(row.attributes.createdAt).format('MM/DD/YYYY'),
      valueFunction: (row) => moment(row.attributes.createdAt).format('MM/DD/YYYY'),
    },
    { name: 'admin',
      header: 'Admin',
      getSortValue: (row) => `${row.attributes.user.fullName} (${row.attributes.user.cssId})`,
      valueFunction: (row) => `${row.attributes.user.fullName} (${row.attributes.user.cssId})`,
    },
    { name: 'description',
      header: 'Description',
      valueFunction: (row) => row.attributes.description
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
