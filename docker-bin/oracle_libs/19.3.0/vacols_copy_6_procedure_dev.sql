
  CREATE OR REPLACE PROCEDURE "VACOLS_DEV"."EBENEFITS" (
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

select  slogid into cnum from corres where ssn = inssn;

select snamel, snamef, bfcorlid, bfmpro, bfcurloc
  into lname, fname, appealid, status, curloc
  from brieff, corres where bfcorkey = stafkey and bfcorlid = cnum;

end;
/


  CREATE OR REPLACE PROCEDURE "VACOLS_DEV"."EBENEFITS2" (
inssn in varchar2
)

is
cnum varchar2(10);

begin

select slogid into cnum from corres where ssn = inssn;

FOR r IN (select snamel, snamef, bfcorlid, bfmpro, bfcurloc
  from brieff, corres where bfcorkey = stafkey and bfcorlid = cnum)
  LOOP
    dbms_output.put_line(r.bfcurloc);
  END LOOP;

end;
/

GRANT EXECUTE on dmdftypes to sys;
/

  CREATE OR REPLACE PROCEDURE "VACOLS_DEV"."MATRIX_DEL" (fkey IN dmdftypes.ftypkey%TYPE,
                                        fval IN dmdftypes.ftypval%TYPE)
AS
BEGIN
  if substr(fval,1,2) = 'AC' then
     UPDATE FTYPES_MATRIX
     SET ftyac = NULL
     WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'DC' then
              if  substr(fval,3,1) = '1' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc1 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '2' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc2 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '3' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc3 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '4' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc4 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '5' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc5 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '6' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc6 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '7' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc7 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '8' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc8 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '9' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc9 = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'A' then
                     UPDATE FTYPES_MATRIX
                        SET ftydca = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'B' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcb = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'C' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcc = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'D' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcd = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'E' then
                     UPDATE FTYPES_MATRIX
                        SET ftydce = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'F' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcf = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'R' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcr = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'W' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcw = NULL,
                        ftydc = NULL
                     WHERE ftypkey = fkey;
              end if;
  elsif substr(fval,1,2) = 'HA' then
        UPDATE FTYPES_MATRIX
        SET ftyha = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'IC' then
        UPDATE FTYPES_MATRIX
        SET ftyic = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'IO' then
        UPDATE FTYPES_MATRIX
        SET ftyio = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'MA' then
        UPDATE FTYPES_MATRIX
        SET ftyma = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'MS' then
        UPDATE FTYPES_MATRIX
        SET ftyms = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'OC' then
        UPDATE FTYPES_MATRIX
        SET ftyoc = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'SH' then
        UPDATE FTYPES_MATRIX
        SET ftysh = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'SO' then
        UPDATE FTYPES_MATRIX
        SET ftyso = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'ST' then
        UPDATE FTYPES_MATRIX
        SET ftyst = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'SQ' then
        UPDATE FTYPES_MATRIX
        SET ftysq = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'MP' then
        UPDATE FTYPES_MATRIX
        SET ftymp = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'CA' then
        UPDATE FTYPES_MATRIX
        SET ftyca = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'HR' then
        UPDATE FTYPES_MATRIX
        SET ftyhr = NULL
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'NU' then
        UPDATE FTYPES_MATRIX
        SET ftynu = NULL
        WHERE ftypkey = fkey;
  end if;
  delete from ftypes_matrix
  where ftypkey = fkey
  and (ftyac is null and ftydc is null and ftyha is null
   and ftyic is null and ftyio is null and ftyma is null
   and ftyms is null and ftyoc is null and ftysh is null
   and ftyso is null and ftyst is null and ftysq is null
   and ftymp is null and ftyca is null and ftyhr is null
   and ftynu is null);
end matrix_del;
/


  CREATE OR REPLACE PROCEDURE "VACOLS_DEV"."MATRIX_INS" (fkey IN dmdftypes.ftypkey%TYPE,
                                        fval IN dmdftypes.ftypval%TYPE,
                                        adusr IN dmdftypes.ftyadusr%TYPE,
                                        adtim IN dmdftypes.ftyadtim%TYPE,
                                        actve IN dmdftypes.ftyactve%TYPE)
AS
BEGIN
  if substr(fval,1,2) = 'AC' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyac, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'DC' then
              if  substr(fval,3,1) = '1' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc1, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '2' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc2, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '3' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc3, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '4' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc4, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '5' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc5, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '6' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc6, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '7' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc7, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '8' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc8, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = '9' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydc9, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'A' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydca, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'B' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydcb, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'C' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydcc, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'D' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydcd, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'E' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydce, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'F' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydcf, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'R' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydcr, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              elsif substr(fval,3,1) = 'W' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftydc, ftyadusr, ftyadtim,
     ftydcw, ftyactve)
     VALUES (fkey, fval, adusr, adtim, fval, actve);
              end if;
  elsif substr(fval,1,2) = 'HA' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyha, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'IC' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyic, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'IO' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyio, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'MA' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyma, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'MS' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyms, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'OC' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyoc, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'SH' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftysh, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'SO' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyso, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'ST' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyst, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'SQ' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftysq, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'MP' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftymp, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'CA' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyca, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'HR' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftyhr, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  elsif substr(fval,1,2) = 'NU' then
     INSERT INTO FTYPES_MATRIX (ftypkey, ftynu, ftyadusr, ftyadtim, ftyactve)
     VALUES (fkey, fval, adusr, adtim, actve);
  end if;
end matrix_ins;
/


  CREATE OR REPLACE PROCEDURE "VACOLS_DEV"."MATRIX_UPD" (fkey IN dmdftypes.ftypkey%TYPE,
                                        fval IN dmdftypes.ftypval%TYPE,
                                        mdusr IN dmdftypes.ftymdusr%TYPE,
                                        mdtim IN dmdftypes.ftymdtim%TYPE,
                                        actve IN dmdftypes.ftyactve%TYPE)
AS
BEGIN
  if substr(fval,1,2) = 'AC' then
     UPDATE FTYPES_MATRIX
     SET ftyac = fval,
         ftymdusr = mdusr,
         ftymdtim = mdtim,
         ftyactve = actve
     WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'DC' then
              if  substr(fval,3,1) = '1' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc1 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '2' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc2 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '3' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc3 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '4' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc4 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '5' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc5 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '6' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc6 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '7' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc7 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '8' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc8 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = '9' then
                     UPDATE FTYPES_MATRIX
                        SET ftydc9 = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'A' then
                     UPDATE FTYPES_MATRIX
                        SET ftydca = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'B' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcb = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'C' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcc = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'D' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcd = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'E' then
                     UPDATE FTYPES_MATRIX
                        SET ftydce = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'F' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcf = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'R' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcr = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              elsif substr(fval,3,1) = 'W' then
                     UPDATE FTYPES_MATRIX
                        SET ftydcw = fval,
                        ftydc = fval,
                        ftymdusr = mdusr,
                        ftymdtim = mdtim,
                        ftyactve = actve
                     WHERE ftypkey = fkey;
              end if;
  elsif substr(fval,1,2) = 'HA' then
        UPDATE FTYPES_MATRIX
        SET ftyha = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'IC' then
        UPDATE FTYPES_MATRIX
        SET ftyic = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'IO' then
        UPDATE FTYPES_MATRIX
        SET ftyio = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'MA' then
        UPDATE FTYPES_MATRIX
        SET ftyma = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'MS' then
        UPDATE FTYPES_MATRIX
        SET ftyms = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'OC' then
        UPDATE FTYPES_MATRIX
        SET ftyoc = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'SH' then
        UPDATE FTYPES_MATRIX
        SET ftysh = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'SO' then
        UPDATE FTYPES_MATRIX
        SET ftyso = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'ST' then
        UPDATE FTYPES_MATRIX
        SET ftyst = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'SQ' then
        UPDATE FTYPES_MATRIX
        SET ftysq = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'MP' then
        UPDATE FTYPES_MATRIX
        SET ftymp = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'CA' then
        UPDATE FTYPES_MATRIX
        SET ftyca = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'HR' then
        UPDATE FTYPES_MATRIX
        SET ftyhr = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  elsif substr(fval,1,2) = 'NU' then
        UPDATE FTYPES_MATRIX
        SET ftynu = fval,
            ftymdusr = mdusr,
            ftymdtim = mdtim,
            ftyactve = actve
        WHERE ftypkey = fkey;
  end if;
end matrix_upd;
/
