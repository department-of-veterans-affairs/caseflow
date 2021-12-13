
import React, { useState, useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import { css } from 'glamor';
import * as yup from 'yup';

import ApiUtil from '../util/ApiUtil';
import Alert from 'app/components/Alert';
import AddressForm from 'app/components/AddressForm';
import DateSelector from 'app/components/DateSelector';
import { TextField } from 'app/components/TextField';
import RadioField from 'app/components/RadioField';
import { FORM_ERROR_FIELD_REQUIRED, FORM_ERROR_FIELD_INVALID, MPI_SEARCH_ERRORS } from '../../COPY';

const alertStyling = css({
  marginBottom: '30px',
});

export default function MPISearch() {
  const mpiSearchschema = yup.object().shape({
    lastName: yup.string().required(FORM_ERROR_FIELD_REQUIRED),
    firstName: yup.string().required(FORM_ERROR_FIELD_REQUIRED),
    middle: yup.string(),
    ssn: yup.string(),
    dateOfBirth: yup.date().
      required(FORM_ERROR_FIELD_REQUIRED).
      max(new Date(), 'Date cannot be in the future').
      typeError(FORM_ERROR_FIELD_INVALID),
    gender: yup.mixed().oneOf(['M', 'F']),
    addressLine1: yup.string(),
    addressLine2: yup.string(),
    addressLine3: yup.string(),
    city: yup.string(),
    zip: yup.string(),
    telephone: yup.string().typeError(FORM_ERROR_FIELD_INVALID)
  });

  const defaultFormValues = {
    lastName: null,
    firstName: null,
    middleName: null,
    ssn: null,
    dateOfBirth: null,
    gender: null,
    addressLine1: null,
    addressLine2: null,
    addressLine3: null,
    city: null,
    state: null,
    zip: null,
    country: null,
    phoneNumber: null,
  };

  const methods = useForm({
    resolver: yupResolver(mpiSearchschema),
    defaultValues: { ...defaultFormValues }
  });

  const {
    register,
    formState: { errors },
    handleSubmit,
  } = methods;

  const [mpiSearchResults, setMpiSearchResults] = useState([]);
  const [lastName, setLastName] = useState('');
  const [firstName, setFirstName] = useState('');
  const [middleName, setMiddleName] = useState('');
  const [ssn, setSSN] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState(null);
  const [gender, setGender] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const [searchSubmitted, setSearchSubmitted] = useState(false);
  const [searchError, setSearchError] = useState(null);
  const [errorCopy, setErrorCopy] = useState(MPI_SEARCH_ERRORS.NOT_REACHABLE);
  const genderOptions = [
    { displayText: 'Male', value: 'M' },
    { displayText: 'Female', value: 'F' }
  ];

  const onSubmit = (formData) => {
    const queryFromData = {
      last_name: formData.lastName,
      first_name: formData.firstName,
      middle_name: formData.middleName,
      ssn: formData.ssn,
      date_of_birth: formData.dateOfBirth,
      gender: formData.gender,
      addressLine1: formData.addressLine1,
      addressLine2: formData.addressLine2,
      addressLine3: formData.addressLine3,
      city: formData.city,
      state: formData.state,
      zip: formData.zip,
      country: formData.country,
      telephone: formData.phoneNumber
    };

    ApiUtil.post('/mpi/search', { data: queryFromData }).
      then((response) => {
        setMpiSearchResults(response.body);
        setSearchSubmitted(true);
        setSearchError(null);
      }).
      catch((error) => {
        setMpiSearchResults([]);
        setSearchError(error);
      });
  };

  useEffect(
    () => {
      if (searchError) {
        const errorText = searchError.response.body.error;

        if (errorText.startsWith('MPI::NotFoundError')) {
          setErrorCopy(MPI_SEARCH_ERRORS.NOT_FOUND);
        } else if (errorText.startsWith('MPI::QueryResultError')) {
          setErrorCopy(MPI_SEARCH_ERRORS.QUERY_RESULT);
        } else if (errorText.startsWith('MPI::ApplicationError')) {
          setErrorCopy(MPI_SEARCH_ERRORS.APPLICATION_ERROR);
        } else if (errorText.startsWith('Savon::SOAPFault')) {
          setErrorCopy(MPI_SEARCH_ERRORS.NOT_REACHABLE);
        }
      }
    },
    [searchError]
  );

  const searchResultList = mpiSearchResults.map((person, index) => {
    return <div>
      <ul className="usa-unstyled-list">
        { person.name && <li key={`person-${index}-name`}>{person.name}</li> }
        { person.ssn && <li key={`person-${index}-ssn`}>SSN: {person.ssn}</li> }
        { person.birthdate && <li key={`person-${index}-dob`}>DOB: {person.birthdate}</li> }
        { person.gender && <li key={`person-${index}-gender`}>Gender: {person.gender}</li> }
        { person.address && <li key={`person-${index}-address`}>Address: {person.address}</li> }
        { person.status && <li key={`person-${index}-status`}>Status: {person.status}</li> }
        { person.phone && <li key={`person-${index}-phone`}>Phone Number: {person.phone}</li> }
      </ul>
      <div className="cf-help-divider"></div>
    </div>;
  });

  return (
  // TO DO: Split form into own component
    <React.Fragment>
      <h1>MPI Search</h1>
      { searchError &&
        <Alert
          type="error"
          styling={alertStyling}
          title={errorCopy.TITLE}
          message={errorCopy.MESSAGE}
        />
      }
      <form onSubmit={handleSubmit(onSubmit)}>
        <TextField
          name="lastName"
          label="Last Name"
          onChange={(val) => setLastName(val)}
          lastName={lastName}
          inputRef={register}
          errorMessage={errors.lastName?.message}
          required
          strongLabel
        />
        <TextField
          name="firstName"
          label="First Name"
          onChange={(val) => setFirstName(val)}
          firstName={firstName}
          inputRef={register}
          errorMessage={errors.firstName?.message}
          required
          strongLabel
        />
        <TextField
          name="middleName"
          label="Middle Name"
          onChange={(val) => setMiddleName(val)}
          middleName={middleName}
          inputRef={register}
          errorMessage={errors.middleName?.message}
          strongLabel
        />
        <TextField
          name="ssn"
          label="SSN"
          onChange={(val) => setSSN(val)}
          middleName={ssn}
          inputRef={register}
          errorMessage={errors.ssn?.message}
          strongLabel
        />
        <DateSelector
          inputRef={register}
          type="date"
          name="dateOfBirth"
          label="Date of Birth"
          value={dateOfBirth}
          onChange={(val) => setDateOfBirth(val)}
          errorMessage={errors.dateOfBirth?.message}
          required
          strongLabel
        />
        <RadioField
          inputRef={register}
          name="Gender"
          options={genderOptions}
          value={gender}
          onChange={(val) => setGender(val)}
          errorMessage={errors.gender?.message}
          strongLabel
        />

        <AddressForm
          {...methods}
        />

        <TextField
          inputRef={register}
          name="phoneNumber"
          label="Phone Number"
          onChange={(val) => setPhoneNumber(val)}
          value={phoneNumber}
          errorMessage={errors.phoneNumber?.message}
          strongLabel
        />
        <input type="submit" />
      </form>
      { searchSubmitted &&
        <section>
          <h2>Results</h2>
          { mpiSearchResults.length > 0 && mpiSearchResults.length < 11 &&
            <ul className="usa-unstyled-list">{ searchResultList }</ul>
          }
          { mpiSearchResults.length === 0 &&
            <p className="cf-lead-paragraph">No results</p>
          }
          { mpiSearchResults.length > 10 &&
            <p className="cf-lead-paragraph">Too many results. Please narrow search query.</p>
          }
        </section>
      }
      { searchError &&
        <Alert
          type="error"
          styling={alertStyling}
          title={errorCopy.TITLE}
          message={errorCopy.MESSAGE}
        />
      }
    </React.Fragment>
  );
}
