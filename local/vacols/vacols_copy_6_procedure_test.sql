CREATE OR REPLACE PROCEDURE "VACOLS_TEST"."EBENEFITS"(
    inssn in varchar2,
    lname out varchar2,
    fname out varchar2,
    appealid out varchar2,
    status out varchar2,
    curloc out varchar2
)
    is
    cnum varchar2(10);

begin

    select slogid
    into cnum
    from corres
    where ssn = inssn;

    select snamel, snamef, bfcorlid, bfmpro, bfcurloc
    into lname, fname, appealid, status, curloc
    from brieff,
         corres
    where bfcorkey = stafkey
      and bfcorlid = cnum;

end;
/


CREATE OR REPLACE PROCEDURE "VACOLS_TEST"."EBENEFITS2"(
    inssn in varchar2
)
    is
    cnum varchar2(10);

begin

    select slogid
    into cnum
    from corres
    where ssn = inssn;

    FOR r IN (select snamel, snamef, bfcorlid, bfmpro, bfcurloc
              from brieff,
                   corres
              where bfcorkey = stafkey
                and bfcorlid = cnum)
        LOOP
            dbms_output.put_line(r.bfcurloc);
        END LOOP;

end;
/
