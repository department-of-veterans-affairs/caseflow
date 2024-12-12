import React, { useState, useEffect } from 'react';
import PropTypes from 'prop-types';
import Button from '../../../../../components/Button';
import NewLetter from './NewLetter';
import { useSelector } from 'react-redux';

export const AddLetter = (props) => {
  const onContinueStatusChange = props.onContinueStatusChange;

  const responseLetters = useSelector((state) => state.intakeCorrespondence.responseLetters);

  const [letters, setLetters] = useState(Object.keys(responseLetters));

  const [dataLetter, setDataLetter] = useState([]);

  const addLetter = (index) => {
    setLetters([...letters, index]);
  };

  const [unrelatedTasksCanContinue, setUnrelatedTasksCanContinue] = useState(true);

  const canContinue = (currentLetters) => {
    const output = [];
    const opts = ['65 days', 'No response window'];

    for (const [, value] of Object.entries(currentLetters)) {
      if ((value !== null) && (value !== '')) {
        output.push(value);
      }
    }

    if ((output.length === 7) && (opts.includes(output[6]))) {
      return true;
    } else if (output.length === 8) {
      return true;
    }

    return false;
  };

  const taskUpdatedCallback = (updatedTask) => {
    setDataLetter((prevDataLetter) => [...prevDataLetter.filter((cdl) => cdl.id !== updatedTask.id), updatedTask]);
  };

  const removeLetter = (index) => {
    const restLetters = letters.filter((letter) => letter !== index);
    const dls = dataLetter.filter((dl) => dl.id !== index);

    setLetters(restLetters);
    setDataLetter(dls);
  };

  useEffect(() => {
    onContinueStatusChange(unrelatedTasksCanContinue);
  }, [unrelatedTasksCanContinue]);

  useEffect(() => {
    if (letters.length > 0) {
      setUnrelatedTasksCanContinue(false);
    } else {
      setUnrelatedTasksCanContinue(true);
    }
  }, [letters]);

  useEffect(() => {
    if ((dataLetter.length > 0) && letters.length === dataLetter.length) {
      for (let i = 0; i < dataLetter.length; i++) {
        if (canContinue(dataLetter[i])) {
          setUnrelatedTasksCanContinue(true);
        } else {
          setUnrelatedTasksCanContinue(false);
        }
      }
    } else if (letters.length === 0) {
      setUnrelatedTasksCanContinue(true);
    } else {
      setUnrelatedTasksCanContinue(false);
    }

  }, [dataLetter]);

  return (
    <>
      <div className="myletters">
        { letters.map((letter) => (
          <div id={letter} className="letter" key={letter}>
            <NewLetter
              index={letter}
              removeLetter={removeLetter}
              taskUpdatedCallback={taskUpdatedCallback}
              setUnrelatedTasksCanContinue= {setUnrelatedTasksCanContinue}
              currentLetter = {responseLetters && responseLetters[letter]}
            />
          </div>
        )) }
      </div>

      <div className="add-letter-container">
        <Button
          type="button"
          name="addLetter"
          className={['cf-left-side']}
          disabled= {!(letters.length < 3)}
          onClick={() => {
            if (letters.length > 0) {
              addLetter(letters[letters.length - 1] + 1);
            } else {
              addLetter(letters.length + 1);
            }
          }}>
        + Add letter
        </Button>
      </div>
    </>
  );
};

AddLetter.propTypes = {
  removeLetter: PropTypes.func,
  index: PropTypes.number,
  setUnrelatedTasksCanContinue: PropTypes.func,
  onContinueStatusChange: PropTypes.func,
};
