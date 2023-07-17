CREATE EXCEPTION MY_EXCEPTION '';

create or alter procedure PR_FIND_TEXT_IN_DATABASE (
    V_FIND_TABLE varchar(31),
    V_TEXT varchar(1000))
returns (
    RDB$RELATION_NAME varchar(31),
    RDB$FIELD_NAME varchar(31),
    RDB$DESCRIPTION blob sub_type 1 segment size 80,
    V_RETURN blob sub_type 1 segment size 80,
    V_PKS blob sub_type 1 segment size 80,
    V_KEY varchar(1000))
as
declare variable RDB$CONSTRAINT_NAME varchar(31);
declare variable V_SQL varchar(1000);
declare variable V_EXISTS_TABLE integer;
BEGIN
  /**************************************************************************
  *                               Jean Carlos                               *
  ***************************************************************************
  *    Procedimento faz uma varredura em todos os campos da tabela informada*
  * e retorna em qual campo esta o texto ou caracter que foi informado no   *
  * parametro de busca                                                      *
  **************************************************************************/
  V_FIND_TABLE = UPPER(:V_FIND_TABLE);

  RDB$FIELD_NAME    = '';
  RDB$RELATION_NAME = '';
  RDB$DESCRIPTION   = '';
  V_EXISTS_TABLE    = 0;

  FOR
    SELECT CAST(TRIM(RDB$RELATION_FIELDS.RDB$RELATION_NAME) AS VARCHAR(31))
         , CAST(TRIM(RDB$RELATION_FIELDS.RDB$FIELD_NAME) AS VARCHAR(31))
         , RDB$RELATION_FIELDS.RDB$DESCRIPTION
      FROM RDB$RELATION_FIELDS
     WHERE RDB$RELATION_FIELDS.RDB$SYSTEM_FLAG = 0
      INTO :RDB$RELATION_NAME
         , :RDB$FIELD_NAME
         , :RDB$DESCRIPTION
  DO
  BEGIN
    RDB$CONSTRAINT_NAME = '';

    SELECT RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_NAME
      FROM RDB$RELATION_CONSTRAINTS
     WHERE RDB$RELATION_CONSTRAINTS.RDB$CONSTRAINT_TYPE = 'PRIMARY KEY'
       AND RDB$RELATION_CONSTRAINTS.RDB$RELATION_NAME = :RDB$RELATION_NAME
      INTO :RDB$CONSTRAINT_NAME;

    V_PKS = '';

    SELECT LIST(TRIM(RDB$INDEX_SEGMENTS.RDB$FIELD_NAME))
      FROM RDB$INDEX_SEGMENTS
     WHERE RDB$INDEX_SEGMENTS.RDB$INDEX_NAME = :RDB$CONSTRAINT_NAME
      INTO :V_PKS;

    V_PKS = COALESCE(:V_PKS,0);

    V_SQL = '';

    V_SQL = ' SELECT '|| REPLACE(:V_PKS,',',"||';'||") ||', '
                      || :RDB$FIELD_NAME    ||
            '   FROM '|| :RDB$RELATION_NAME ||
            '  WHERE UPPER('|| :RDB$RELATION_NAME ||'.'|| :RDB$FIELD_NAME || ') CONTAINING '''|| :V_TEXT || '''';

    FOR
      EXECUTE STATEMENT :V_SQL
                   INTO :V_KEY
                      , :V_RETURN

    DO
    BEGIN
      SUSPEND;
      V_KEY    = '';
      V_RETURN = '';
    END
    WHEN ANY DO BEGIN
                  EXCEPTION MY_EXCEPTION 'Erro ao executar o filtro, provavelmente o caracter ('||:V_TEXT||') que você está procurando é um caracter inválido';
                END

  END
END