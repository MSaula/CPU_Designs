ADDI 1 0 1     -- Guardem un 1 a R1
JMP 8          -- Saltem a la zona de crida de "funcions"
ADD 12 0 0     -- Forçem un 0 al R12
ADDI 11 0 1    -- Passem un 1 al R11
BEQ 12 10 4    -- En cas de arribar al final del calcul sortim del bucle
ADDI 12 12 1   -- Incrementem R12
MULT 11 11 12  -- Calculem acc * (n+1)
JMP -3         -- En cas de no saltar tornem al inici del bucle
RETURN
ADDI 10 0 12   -- Calculem 12!
CALL -8
ADDI 10 0 5    -- Calculem 5!
CALL -10
ADDI 10 0 0    -- Calculem 0!
CALL -12
CALL 5         -- Calculem el 12! pero de manera recursiva en comptes de iterativa
MI2F 1 1       -- Test senzill pel BFEQ
MI2F 11 2
BFEQ 1 2 2     -- No saltarà
BFEQ 2 2 -19   -- Torna a iniciar l'execució des de la primera instrucció
ADDI 10 0 12   -- Guardem un 12 a R10
ADD 12 0 0     -- Forçem un 0 al R12
ADDI 11 0 1    -- Passem un 1 al R11
BEQ 12 10 4
ADDI 12 12 1   -- Incrementem R12
MULT 11 11 12  -- Calculem acc * (n+1)
CALL -3
RETURN
