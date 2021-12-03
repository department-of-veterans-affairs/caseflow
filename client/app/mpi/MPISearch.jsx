
import React, { useState } from 'react';
import { useForm } from 'react-hook-form';
import { yupResolver } from '@hookform/resolvers/yup';
import * as yup from 'yup';
import { TextField } from '../components/TextField';
import AddressForm from '../components/AddressForm';
import DateSelector from '../components/DateSelector';
import RadioField from '../components/RadioField';
import { FORM_ERROR_FIELD_REQUIRED } from '../../COPY';
import ApiUtil from '../util/ApiUtil';

export default function MPISearch() {
  const mpiSearchschema = yup.object().shape({
    lastName: yup.string().required(FORM_ERROR_FIELD_REQUIRED),
    firstName: yup.string().required(FORM_ERROR_FIELD_REQUIRED),
    middle: yup.string(),
    ssn: yup.string(),
    dateOfBirth: yup.date().
      required(FORM_ERROR_FIELD_REQUIRED).
      max(new Date(), 'Date cannot be in the future'),
    gender: yup.mixed().oneOf(['M', 'F']),
    address: yup.object(),
    telephone: yup.string()
  });

  const [lastName, setLastName] = useState('');
  const [firstName, setFirstName] = useState('');
  const [middleName, setMiddleName] = useState('');
  const [ssn, setSSN] = useState('');
  const [dateOfBirth, setDateOfBirth] = useState(null);
  const [gender, setGender] = useState('');
  const [phoneNumber, setPhoneNumber] = useState('');
  const genderOptions = [
    { displayText: 'Male', value: 'M' },
    { displayText: 'Female', value: 'F' }
  ];

  const methods = useForm({ resolver: yupResolver(mpiSearchschema) });
  const { register, control, handleSubmit, formState: { errors, isDirty } } = methods;
  const onSubmit = (formData) => {
    const queryFromData = {
      last_name: formData.lastName,
      first_name: formData.firstName,
      middle_name: formData.middleName,
      ssn: formData.ssn,
      date_of_birth: formData.dateOfBirth,
      gender: formData.gender,
      address: 'Some address',
      telephone: formData.phoneNumber
    };

    ApiUtil.get('/mpi/search', { query: queryFromData }).
      then((response) => {
        console.log('RESPONSE', response);
      }).
      catch((error) => console.log('ERROR SEARCHING', error));
  };

  return (
    <React.Fragment>
      <h1>MPI Search</h1>
      <form onSubmit={handleSubmit(onSubmit)}>

        <TextField
          name="lastName"
          label="Last Name"
          onChange={(val) => setLastName(val)}
          lastName={lastName}
          inputRef={register}
          // errorMessage={isDirty && errors.lastName?.message}
          required
          strongLabel
        />
        <TextField
          name="firstName"
          label="First Name"
          onChange={(val) => setFirstName(val)}
          firstName={firstName}
          inputRef={register}
          // errorMessage={isDirty && errors.firstName?.message}
          required
          strongLabel
        />
        <TextField
          name="middleName"
          label="Middle Name"
          onChange={(val) => setMiddleName(val)}
          middleName={middleName}
          inputRef={register}
          // errorMessage={isDirty && errors.middleName?.message}
          strongLabel
        />
        <TextField
          name="ssn"
          label="SSN"
          onChange={(val) => setSSN(val)}
          middleName={ssn}
          inputRef={register}
          // errorMessage={isDirty && errors.ssn?.message}
          strongLabel
        />
        <DateSelector
          inputRef={register}
          type="date"
          name="dateOfBirth"
          label="Date of Birth"
          value={dateOfBirth}
          onChange={(val) => setDateOfBirth(val)}
          // errorMessage={isDirty && errors.dateOfBirth?.message}
          required
          strongLabel
        />
        <RadioField
          inputRef={register}
          name="Gender"
          options={genderOptions}
          value={gender}
          onChange={(val) => setGender(val)}
          // errorMessage={isDirty && errors.gender?.message}
          strongLabel
        />
        <AddressForm
          controle={control}
          register={register}
          {...methods} />
        <TextField
          inputRef={register}
          name="phoneNumber"
          label="Phone Number"
          onChange={(val) => setPhoneNumber(val)}
          value={phoneNumber}
          // errorMessage={isDirty && errors.phoneNumber?.message}
          strongLabel
        />
        <input type="submit" />
      </form>
    </React.Fragment>
  );
}
