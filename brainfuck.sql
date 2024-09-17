CREATE TABLE input (
  input text
);

INSERT INTO input VALUES ('');

CREATE TABLE program (
  program text
);


INSERT INTO program VALUES ('>++++++++[<+++++++++>-]<.>++++[<+++++++>-]<+.+++++++..+++.>>++++++[<+++++++>-]<+
+.------------.>++++++[<+++++++++>-]<+.<.+++.------.--------.>>>++++[<++++++++>-
]<+.$');


WITH RECURSIVE run_state 
  (iteration, input, output, band, band_position, program, program_position, halted) AS (
    SELECT 
      0,
      input,
      ''::text,
      repeat('\000'::text, 30000)::bytea,
      0,
      program,
      1,
      false
    FROM input
    CROSS JOIN program
    UNION ALL
    SELECT
      iteration + 1,
      CASE
        WHEN substring(program, program_position, 1) = ',' THEN substring(input from 2)
        ELSE input
      END,
      CASE 
        WHEN substring(program, program_position, 1) = '.' THEN output || chr(get_byte(band, band_position))
        ELSE output
      END,
      CASE
        WHEN substring(program, program_position, 1) = ',' THEN set_byte(band, band_position, ascii(substring(input, 1, 1)))
        WHEN substring(program, program_position, 1) = '+' THEN set_byte(band, band_position, get_byte(band, band_position) + 1)
        WHEN substring(program, program_position, 1) = '-' THEN set_byte(band, band_position, get_byte(band, band_position) - 1)
        ELSE band
      END,
      CASE
        WHEN substring(program, program_position, 1) = '<' THEN band_position - 1
        WHEN substring(program, program_position, 1) = '>' THEN band_position + 1
        ELSE band_position
      END,
      program,
      CASE
        WHEN substring(program, program_position, 1) = '[' THEN
          CASE 
            WHEN get_byte(band, band_position) = 0 THEN
              (
                WITH RECURSIVE forward_search (position, stack, done) AS (
                  SELECT program_position + 1, 0, false
                  UNION ALL
                  SELECT 
                    position + 1,
                    CASE
                      WHEN substring(program, position, 1) = '[' THEN stack + 1
                      WHEN substring(program, position, 1) = ']' THEN stack - 1
                      ELSE stack
                    END,
                    substring(program, position, 1) = ']' AND stack = 0
                  FROM forward_search
                  WHERE NOT done
                )
                SELECT position
                FROM forward_search
                WHERE done
              )
            ELSE program_position + 1
          END
        WHEN substring(program, program_position, 1) = ']' THEN
          CASE
            WHEN get_byte(band, band_position) = 0 THEN program_position + 1
            ELSE 
              (
                WITH RECURSIVE backward_search (position, stack, done) AS (
                  SELECT program_position - 1, 0, false
                  UNION ALL
                  SELECT 
                    position - 1,
                    CASE
                      WHEN substring(program, position, 1) = ']' THEN stack + 1
                      WHEN substring(program, position, 1) = '[' THEN stack - 1
                      ELSE stack
                    END,
                    substring(program, position, 1) = '[' AND stack = 0
                  FROM backward_search
                  WHERE NOT done
                )
                SELECT position + 2
                FROM backward_search
                WHERE done
              )
          END
        ELSE program_position + 1
      END,
      substring(program, program_position, 1) = '$'
    FROM run_state
    WHERE NOT halted
  )
SELECT iteration, output
FROM run_state
WHERE halted





