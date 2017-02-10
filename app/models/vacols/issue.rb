class VACOLS::Issue < VACOLS::Record
  self.table_name = "vacols.issues"
  self.sequence_name = "vacols.issseq"
  self.primary_key = "isskey"

  DISPOSITION_CODE = {
    "1" => "Grant",
    "3" => "Remand"
  }.freeze

  def description
    conn = self.class.connection
    key = conn.quote(isskey)

    issref = conn.exec_query(<<-SQL).rows.first
      SELECT LEV1_DESC, LEV2_DESC, LEV3_DESC, ISSKEY, PROG_DESC,
	     ISS_DESC, ISSLEV1, ISSLEV2, ISSLEV3, LEV1_CODE, LEV2_CODE, LEV3_CODE
        FROM ISSREF, ISSUES
        WHERE issues.ISSPROG = issref.PROG_CODE
          AND issues.ISSCODE = issref.ISS_CODE
          AND (issues.ISSLEV1 = issref.LEV1_CODE
	    OR issues.ISSLEV1 IS NULL
            OR issref.LEV1_CODE = '##')
          AND (issues.ISSLEV2 = issref.LEV2_CODE
	    OR issues.ISSLEV2 IS NULL
            OR issref.LEV2_CODE = '##')
          AND (issues.ISSLEV3 = issref.LEV3_CODE
	    OR issues.ISSLEV3 IS NULL
            OR issref.LEV3_CODE = '##')
          AND issues.isskey = #{key}
    SQL

    if issref[0..2].include?("Diagnostic code")
      vftype_key = conn.quote()
      vftype = conn.exec_query(<<-SQL).rows.first
	SELECT FTDESC FROM VFTYPES WHERE FTKEY = #{vftype_key}
      SQL
    end
    
  end
end
